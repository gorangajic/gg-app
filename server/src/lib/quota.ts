import { prisma } from './prisma';
import { logInfo, logWarn } from './logger';

export const DEFAULT_DAILY_QUOTA = 100;

export async function checkQuota(userId: string): Promise<{
  allowed: boolean;
  remaining: number;
  resetAt: Date;
  quota: number;
}> {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      dailyQuota: true,
      usedQuota: true,
      quotaResetAt: true,
    },
  });

  if (!user) {
    throw new Error('User not found');
  }

  const now = new Date();

  // Reset quota if the reset time has passed
  if (user.quotaResetAt <= now) {
    await prisma.user.update({
      where: { id: userId },
      data: {
        usedQuota: 0,
        quotaResetAt: getNextResetTime(),
      },
    });

    return {
      allowed: true,
      remaining: user.dailyQuota - 1,
      resetAt: getNextResetTime(),
      quota: user.dailyQuota,
    };
  }

  const remaining = user.dailyQuota - user.usedQuota;

  if (remaining <= 0) {
    logWarn('Quota exceeded', { userId, quota: user.dailyQuota, used: user.usedQuota });
    return {
      allowed: false,
      remaining: 0,
      resetAt: user.quotaResetAt,
      quota: user.dailyQuota,
    };
  }

  return {
    allowed: true,
    remaining,
    resetAt: user.quotaResetAt,
    quota: user.dailyQuota,
  };
}

export async function incrementQuota(userId: string): Promise<void> {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      usedQuota: true,
      quotaResetAt: true,
    },
  });

  if (!user) {
    throw new Error('User not found');
  }

  const now = new Date();

  // Reset if needed
  if (user.quotaResetAt <= now) {
    await prisma.user.update({
      where: { id: userId },
      data: {
        usedQuota: 1,
        quotaResetAt: getNextResetTime(),
      },
    });
  } else {
    await prisma.user.update({
      where: { id: userId },
      data: {
        usedQuota: user.usedQuota + 1,
      },
    });
  }

  logInfo('Quota incremented', { userId, newUsage: user.usedQuota + 1 });
}

export async function getQuotaInfo(userId: string): Promise<{
  quota: number;
  used: number;
  remaining: number;
  resetAt: Date;
}> {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      dailyQuota: true,
      usedQuota: true,
      quotaResetAt: true,
    },
  });

  if (!user) {
    throw new Error('User not found');
  }

  const now = new Date();

  // Reset if needed
  if (user.quotaResetAt <= now) {
    await prisma.user.update({
      where: { id: userId },
      data: {
        usedQuota: 0,
        quotaResetAt: getNextResetTime(),
      },
    });

    return {
      quota: user.dailyQuota,
      used: 0,
      remaining: user.dailyQuota,
      resetAt: getNextResetTime(),
    };
  }

  return {
    quota: user.dailyQuota,
    used: user.usedQuota,
    remaining: Math.max(0, user.dailyQuota - user.usedQuota),
    resetAt: user.quotaResetAt,
  };
}

export async function updateUserQuota(userId: string, newQuota: number): Promise<void> {
  await prisma.user.update({
    where: { id: userId },
    data: {
      dailyQuota: newQuota,
    },
  });

  logInfo('User quota updated', { userId, newQuota });
}

function getNextResetTime(): Date {
  const resetTime = new Date();
  resetTime.setHours(24, 0, 0, 0); // Next midnight
  return resetTime;
}
