import { NextRequest, NextResponse } from 'next/server';
import { authenticate } from '@/lib/middleware';
import { getQuotaInfo } from '@/lib/quota';
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
    const quotaInfo = await getQuotaInfo(authResult.user.id);

    return NextResponse.json(
      {
        quota: quotaInfo,
      },
      { status: 200, headers: rateLimitResult.headers }
    );
  } catch (error) {
    logError({ error, userId: authResult.user.id, message: 'Get quota error' });
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
