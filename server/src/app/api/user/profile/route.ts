import { NextRequest, NextResponse } from 'next/server';
import { authenticate } from '@/lib/middleware';
import { prisma } from '@/lib/prisma';
import { hashPassword } from '@/lib/auth';
import { logInfo, logError } from '@/lib/logger';
import { apiRateLimiter } from '@/lib/rate-limiter';
import { z } from 'zod';

const updateProfileSchema = z.object({
  name: z.string().min(1).optional(),
  email: z.string().email().optional(),
  currentPassword: z.string().optional(),
  newPassword: z.string().min(8).optional(),
});

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
    const user = await prisma.user.findUnique({
      where: { id: authResult.user.id },
      select: {
        id: true,
        email: true,
        name: true,
        emailVerified: true,
        dailyQuota: true,
        usedQuota: true,
        quotaResetAt: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    if (!user) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 });
    }

    return NextResponse.json(
      { user },
      { status: 200, headers: rateLimitResult.headers }
    );
  } catch (error) {
    logError({ error, userId: authResult.user.id, message: 'Get profile error' });
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

export async function PATCH(request: NextRequest) {
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
    const body = await request.json();
    const validation = updateProfileSchema.safeParse(body);

    if (!validation.success) {
      return NextResponse.json(
        { error: 'Validation error', details: validation.error.errors },
        { status: 400 }
      );
    }

    const { name, email, currentPassword, newPassword } = validation.data;
    const updateData: any = {};

    // Update name if provided
    if (name !== undefined) {
      updateData.name = name;
    }

    // Update email if provided (requires re-verification)
    if (email !== undefined && email !== authResult.user.email) {
      const existingUser = await prisma.user.findUnique({
        where: { email },
      });

      if (existingUser) {
        return NextResponse.json(
          { error: 'Email already in use' },
          { status: 409 }
        );
      }

      updateData.email = email;
      updateData.emailVerified = false;
      // TODO: Send verification email to new address
    }

    // Update password if provided
    if (newPassword && currentPassword) {
      const user = await prisma.user.findUnique({
        where: { id: authResult.user.id },
      });

      if (!user) {
        return NextResponse.json({ error: 'User not found' }, { status: 404 });
      }

      const bcrypt = await import('bcryptjs');
      const isValidPassword = await bcrypt.compare(currentPassword, user.password);

      if (!isValidPassword) {
        return NextResponse.json(
          { error: 'Current password is incorrect' },
          { status: 401 }
        );
      }

      updateData.password = await hashPassword(newPassword);
    } else if (newPassword || currentPassword) {
      return NextResponse.json(
        { error: 'Both current and new passwords are required to change password' },
        { status: 400 }
      );
    }

    const updatedUser = await prisma.user.update({
      where: { id: authResult.user.id },
      data: updateData,
      select: {
        id: true,
        email: true,
        name: true,
        emailVerified: true,
        dailyQuota: true,
        usedQuota: true,
        quotaResetAt: true,
        updatedAt: true,
      },
    });

    logInfo('User profile updated', {
      userId: authResult.user.id,
      updatedFields: Object.keys(updateData),
    });

    return NextResponse.json(
      {
        message: 'Profile updated successfully',
        user: updatedUser,
      },
      { status: 200, headers: rateLimitResult.headers }
    );
  } catch (error) {
    logError({ error, userId: authResult.user.id, message: 'Update profile error' });
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
