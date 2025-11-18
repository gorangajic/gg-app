import { NextRequest, NextResponse } from 'next/server';
import { createPasswordResetToken } from '@/lib/auth';
import { sendPasswordResetEmail } from '@/lib/email';
import { prisma } from '@/lib/prisma';
import { logInfo, logError } from '@/lib/logger';
import { strictRateLimiter } from '@/lib/rate-limiter';
import { z } from 'zod';

const forgotPasswordSchema = z.object({
  email: z.string().email('Invalid email address'),
});

export async function POST(request: NextRequest) {
  // Apply strict rate limiting for password reset requests
  const rateLimitResult = await strictRateLimiter(request);
  if ('status' in rateLimitResult) {
    return rateLimitResult;
  }

  try {
    const body = await request.json();
    const { email } = forgotPasswordSchema.parse(body);

    logInfo('Password reset request', { email });

    const token = await createPasswordResetToken(email);

    // Always return success to prevent email enumeration
    if (!token) {
      logInfo('Password reset request: User not found', { email });
      return NextResponse.json(
        {
          message:
            'If your email is registered, you will receive a password reset link shortly.',
        },
        { status: 200, headers: rateLimitResult.headers }
      );
    }

    const user = await prisma.user.findUnique({
      where: { email },
    });

    if (user) {
      try {
        await sendPasswordResetEmail(email, token, user.name || undefined);
        logInfo('Password reset email sent successfully', {
          userId: user.id,
          email,
        });
      } catch (error) {
        logError({
          error,
          message: 'Failed to send password reset email',
          userId: user.id,
        });
        return NextResponse.json(
          { error: 'Failed to send password reset email. Please try again later.' },
          { status: 500 }
        );
      }
    }

    return NextResponse.json(
      {
        message:
          'If your email is registered, you will receive a password reset link shortly.',
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

    logError({ error, message: 'Forgot password error' });

    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
