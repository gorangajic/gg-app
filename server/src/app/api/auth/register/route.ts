import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { prisma } from '@/lib/prisma';
import {
  hashPassword,
  generateToken,
  createSession,
  createVerificationToken,
} from '@/lib/auth';
import { sendVerificationEmail } from '@/lib/email';
import { logInfo, logError } from '@/lib/logger';
import { authRateLimiter } from '@/lib/rate-limiter';

const registerSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
  name: z.string().optional(),
});

export async function POST(request: NextRequest) {
  // Apply rate limiting
  const rateLimitResult = await authRateLimiter(request);
  if ('status' in rateLimitResult) {
    return rateLimitResult;
  }

  try {
    const body = await request.json();
    const validation = registerSchema.safeParse(body);

    if (!validation.success) {
      return NextResponse.json(
        { error: 'Validation error', details: validation.error.errors },
        { status: 400 }
      );
    }

    const { email, password, name } = validation.data;

    logInfo('User registration attempt', { email });

    // Check if user already exists
    const existingUser = await prisma.user.findUnique({
      where: { email },
    });

    if (existingUser) {
      logInfo('Registration failed: User already exists', { email });
      return NextResponse.json(
        { error: 'User with this email already exists' },
        { status: 409 }
      );
    }

    // Hash password and create user
    const hashedPassword = await hashPassword(password);
    const user = await prisma.user.create({
      data: {
        email,
        password: hashedPassword,
        name,
      },
      select: {
        id: true,
        email: true,
        name: true,
        emailVerified: true,
        createdAt: true,
      },
    });

    logInfo('User created successfully', { userId: user.id, email: user.email });

    // Create verification token and send email
    try {
      const verificationToken = await createVerificationToken(user.id);
      await sendVerificationEmail(email, verificationToken, name);
      logInfo('Verification email sent', { userId: user.id });
    } catch (error) {
      logError({
        error,
        message: 'Failed to send verification email',
        userId: user.id,
      });
      // Continue with registration even if email fails
    }

    // Generate token and create session
    const token = generateToken({ userId: user.id, email: user.email });
    await createSession(user.id, token);

    return NextResponse.json(
      {
        message:
          'User registered successfully. Please check your email to verify your account.',
        user,
        token,
      },
      { status: 201, headers: rateLimitResult.headers }
    );
  } catch (error) {
    logError({ error, message: 'Registration error' });
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
