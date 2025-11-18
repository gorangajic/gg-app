import { NextRequest, NextResponse } from 'next/server';
import { verifyEmailToken } from '@/lib/auth';
import { sendWelcomeEmail } from '@/lib/email';
import { logInfo, logError } from '@/lib/logger';
import { z } from 'zod';

const verifySchema = z.object({
  token: z.string().min(1, 'Verification token is required'),
});

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { token } = verifySchema.parse(body);

    logInfo('Email verification attempt', { token: token.substring(0, 10) + '...' });

    const user = await verifyEmailToken(token);

    if (!user) {
      logInfo('Email verification failed: Invalid or expired token');
      return NextResponse.json(
        { error: 'Invalid or expired verification token' },
        { status: 400 }
      );
    }

    logInfo('Email verified successfully', { userId: user.id, email: user.email });

    // Send welcome email
    try {
      await sendWelcomeEmail(user.email, user.name || undefined);
    } catch (error) {
      logError({
        error,
        message: 'Failed to send welcome email',
        userId: user.id,
      });
      // Don't fail the verification if welcome email fails
    }

    return NextResponse.json(
      {
        message: 'Email verified successfully',
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          emailVerified: true,
        },
      },
      { status: 200 }
    );
  } catch (error) {
    if (error instanceof z.ZodError) {
      return NextResponse.json(
        { error: 'Validation error', details: error.errors },
        { status: 400 }
      );
    }

    logError({ error, message: 'Email verification error' });

    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
