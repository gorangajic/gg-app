import { NextRequest, NextResponse } from 'next/server';
import { logWarn } from './logger';

interface RateLimitEntry {
  count: number;
  resetTime: number;
}

class RateLimiter {
  private limits: Map<string, RateLimitEntry> = new Map();
  private cleanupInterval: NodeJS.Timeout;

  constructor() {
    // Clean up expired entries every 60 seconds
    this.cleanupInterval = setInterval(() => {
      this.cleanup();
    }, 60000);
  }

  private cleanup() {
    const now = Date.now();
    for (const [key, entry] of this.limits.entries()) {
      if (entry.resetTime < now) {
        this.limits.delete(key);
      }
    }
  }

  check(identifier: string, maxRequests: number, windowMs: number): boolean {
    const now = Date.now();
    const entry = this.limits.get(identifier);

    if (!entry || entry.resetTime < now) {
      // New window or expired
      this.limits.set(identifier, {
        count: 1,
        resetTime: now + windowMs,
      });
      return true;
    }

    if (entry.count >= maxRequests) {
      return false;
    }

    entry.count++;
    return true;
  }

  getRemainingRequests(
    identifier: string,
    maxRequests: number
  ): { remaining: number; resetTime: number } {
    const entry = this.limits.get(identifier);
    if (!entry) {
      return { remaining: maxRequests, resetTime: Date.now() };
    }
    return {
      remaining: Math.max(0, maxRequests - entry.count),
      resetTime: entry.resetTime,
    };
  }

  destroy() {
    clearInterval(this.cleanupInterval);
  }
}

export const rateLimiter = new RateLimiter();

export interface RateLimitConfig {
  maxRequests?: number; // Max requests per window
  windowMs?: number; // Time window in milliseconds
  skipSuccessfulRequests?: boolean;
  keyGenerator?: (request: NextRequest) => string;
}

const defaultConfig: Required<RateLimitConfig> = {
  maxRequests: 100,
  windowMs: 15 * 60 * 1000, // 15 minutes
  skipSuccessfulRequests: false,
  keyGenerator: (request) => {
    // Use IP address as default identifier
    const forwarded = request.headers.get('x-forwarded-for');
    const ip = forwarded ? forwarded.split(',')[0] : request.ip || 'unknown';
    return ip;
  },
};

export function createRateLimitMiddleware(config: RateLimitConfig = {}) {
  const mergedConfig = { ...defaultConfig, ...config };

  return async (request: NextRequest) => {
    const identifier = mergedConfig.keyGenerator(request);
    const allowed = rateLimiter.check(
      identifier,
      mergedConfig.maxRequests,
      mergedConfig.windowMs
    );

    if (!allowed) {
      const { remaining, resetTime } = rateLimiter.getRemainingRequests(
        identifier,
        mergedConfig.maxRequests
      );

      logWarn('Rate limit exceeded', {
        identifier,
        endpoint: request.nextUrl.pathname,
        method: request.method,
      });

      return NextResponse.json(
        {
          error: 'Too many requests',
          message: 'Rate limit exceeded. Please try again later.',
          retryAfter: Math.ceil((resetTime - Date.now()) / 1000),
        },
        {
          status: 429,
          headers: {
            'X-RateLimit-Limit': mergedConfig.maxRequests.toString(),
            'X-RateLimit-Remaining': remaining.toString(),
            'X-RateLimit-Reset': new Date(resetTime).toISOString(),
            'Retry-After': Math.ceil((resetTime - Date.now()) / 1000).toString(),
          },
        }
      );
    }

    const { remaining, resetTime } = rateLimiter.getRemainingRequests(
      identifier,
      mergedConfig.maxRequests
    );

    return {
      allowed: true,
      headers: {
        'X-RateLimit-Limit': mergedConfig.maxRequests.toString(),
        'X-RateLimit-Remaining': remaining.toString(),
        'X-RateLimit-Reset': new Date(resetTime).toISOString(),
      },
    };
  };
}

// Pre-configured rate limiters for different endpoints
export const authRateLimiter = createRateLimitMiddleware({
  maxRequests: 5,
  windowMs: 15 * 60 * 1000, // 5 requests per 15 minutes
});

export const apiRateLimiter = createRateLimitMiddleware({
  maxRequests: 100,
  windowMs: 15 * 60 * 1000, // 100 requests per 15 minutes
});

export const strictRateLimiter = createRateLimitMiddleware({
  maxRequests: 3,
  windowMs: 60 * 60 * 1000, // 3 requests per hour
});
