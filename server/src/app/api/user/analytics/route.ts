import { NextRequest, NextResponse } from 'next/server';
import { authenticate } from '@/lib/middleware';
import { prisma } from '@/lib/prisma';
import { logError } from '@/lib/logger';
import { apiRateLimiter } from '@/lib/rate-limiter';

export async function GET(request: NextRequest) {
  // Apply rate limiting
  const rateLimitResult = await apiRateLimiter(request);
  if ('status' in rateLimitResult) {
    return rateLimitResult;
  }

  const authResult = await authenticate(request);
  if ('status' in authResult) {
    return authResult;
  }

  try {
    const { searchParams } = new URL(request.url);
    const days = parseInt(searchParams.get('days') || '7');

    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    // Get request count by endpoint
    const requestsByEndpoint = await prisma.requestHistory.groupBy({
      by: ['endpoint'],
      where: {
        userId: authResult.user.id,
        createdAt: { gte: startDate },
      },
      _count: true,
    });

    // Get average processing time by endpoint
    const avgProcessingTime = await prisma.requestHistory.groupBy({
      by: ['endpoint'],
      where: {
        userId: authResult.user.id,
        createdAt: { gte: startDate },
      },
      _avg: {
        processingTime: true,
      },
    });

    // Get status code distribution
    const statusCodes = await prisma.requestHistory.groupBy({
      by: ['statusCode'],
      where: {
        userId: authResult.user.id,
        createdAt: { gte: startDate },
      },
      _count: true,
    });

    // Get total requests
    const totalRequests = await prisma.requestHistory.count({
      where: {
        userId: authResult.user.id,
        createdAt: { gte: startDate },
      },
    });

    // Get daily request counts
    const dailyRequests = await prisma.$queryRaw<
      Array<{ date: string; count: bigint }>
    >`
      SELECT
        DATE(created_at) as date,
        COUNT(*) as count
      FROM request_history
      WHERE user_id = ${authResult.user.id}
        AND created_at >= ${startDate}
      GROUP BY DATE(created_at)
      ORDER BY date DESC
    `;

    const analytics = {
      period: {
        days,
        startDate,
        endDate: new Date(),
      },
      summary: {
        totalRequests,
        uniqueEndpoints: requestsByEndpoint.length,
      },
      byEndpoint: requestsByEndpoint.map((r) => ({
        endpoint: r.endpoint,
        count: r._count,
        avgProcessingTime:
          avgProcessingTime.find((a) => a.endpoint === r.endpoint)?._avg
            ?.processingTime || 0,
      })),
      statusCodes: statusCodes.map((s) => ({
        code: s.statusCode,
        count: s._count,
      })),
      dailyActivity: dailyRequests.map((d) => ({
        date: d.date,
        count: Number(d.count),
      })),
    };

    return NextResponse.json(
      { analytics },
      { status: 200, headers: rateLimitResult.headers }
    );
  } catch (error) {
    logError({
      error,
      userId: authResult.user.id,
      message: 'Get analytics error',
    });
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
