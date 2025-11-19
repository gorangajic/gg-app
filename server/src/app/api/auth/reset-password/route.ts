import { NextRequest, NextResponse } from 'next/server';
import { resetPassword } from '@/lib/auth';
import { logInfo, logError } from '@/lib/logger';
import { authRateLimiter } from '@/lib/rate-limiter';
import { z } from 'zod';

const resetPasswordSchema = z.object({
  token: z.string().min(1, 'Reset token is required'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
});

export async function POST(request: NextRequest) {
  // Apply rate limiting
  const rateLimitResult = await authRateLimiter(request);
  if ('status' in rateLimitResult) {
    return rateLimitResult;
  }

  try {
    const body = await request.json();
    const { token, password } = resetPasswordSchema.parse(body);

    logInfo('Password reset attempt', { token: token.substring(0, 10) + '...' });

    const user = await resetPassword(token, password);

    if (!user) {
      logInfo('Password reset failed: Invalid or expired token');
      return NextResponse.json(
        { error: 'Invalid or expired reset token' },
        { status: 400 }
      );
    }

    logInfo('Password reset successfully', { userId: user.id, email: user.email });

    return NextResponse.json(
      {
        message: 'Password reset successfully. Please log in with your new password.',
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
        },
      },
      { status: 200, headers: rateLimitResult.headers }
    );
  } catch (error) {
    if (error instanceof z.ZodError) {
      return NextResponse.json(
        { error: 'Validation error', details: error.errors },
        { status: 400 }
      );
    }

    logError({ error, message: 'Password reset error' });

    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
