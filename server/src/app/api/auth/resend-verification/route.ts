import { NextRequest, NextResponse } from 'next/server';
import { createVerificationToken } from '@/lib/auth';
import { sendVerificationEmail } from '@/lib/email';
import { prisma } from '@/lib/prisma';
import { logInfo, logError } from '@/lib/logger';
import { strictRateLimiter } from '@/lib/rate-limiter';
import { z } from 'zod';

const resendSchema = z.object({
  email: z.string().email('Invalid email address'),
});

export async function POST(request: NextRequest) {
  // Apply strict rate limiting for resend verification
  const rateLimitResult = await strictRateLimiter(request);
  if ('status' in rateLimitResult) {
    return rateLimitResult;
  }

  try {
    const body = await request.json();
    const { email } = resendSchema.parse(body);

    logInfo('Resend verification email attempt', { email });

    const user = await prisma.user.findUnique({
      where: { email },
    });

    // Always return success to prevent email enumeration
    if (!user) {
      logInfo('Resend verification: User not found', { email });
      return NextResponse.json(
        {
          message: 'If your email is registered, you will receive a verification email shortly.',
        },
        { status: 200 }
      );
    }

    if (user.emailVerified) {
      logInfo('Resend verification: Email already verified', { email });
      return NextResponse.json(
        {
          message: 'Email is already verified',
        },
        { status: 200 }
      );
    }

    const token = await createVerificationToken(user.id);

    try {
      await sendVerificationEmail(email, token, user.name || undefined);
      logInfo('Verification email resent successfully', {
        userId: user.id,
        email,
      });
    } catch (error) {
      logError({
        error,
        message: 'Failed to send verification email',
        userId: user.id,
      });
      return NextResponse.json(
        { error: 'Failed to send verification email. Please try again later.' },
        { status: 500 }
      );
    }

    return NextResponse.json(
      {
        message: 'If your email is registered, you will receive a verification email shortly.',
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

    logError({ error, message: 'Resend verification error' });

    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
