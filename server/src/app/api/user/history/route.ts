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
    const limit = parseInt(searchParams.get('limit') || '50');
    const offset = parseInt(searchParams.get('offset') || '0');
    const endpoint = searchParams.get('endpoint');

    const where: any = {
      userId: authResult.user.id,
    };

    if (endpoint) {
      where.endpoint = endpoint;
    }

    const [history, total] = await Promise.all([
      prisma.requestHistory.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        take: Math.min(limit, 100), // Max 100 per request
        skip: offset,
        select: {
          id: true,
          endpoint: true,
          method: true,
          statusCode: true,
          processingTime: true,
          createdAt: true,
        },
      }),
      prisma.requestHistory.count({ where }),
    ]);

    return NextResponse.json(
      {
        history,
        pagination: {
          total,
          limit,
          offset,
          hasMore: offset + limit < total,
        },
      },
      { status: 200, headers: rateLimitResult.headers }
    );
  } catch (error) {
    logError({ error, userId: authResult.user.id, message: 'Get history error' });
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
