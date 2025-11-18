import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { authenticate } from '@/lib/middleware';
import {
  getOpenAIClient,
  AI_CONFIG,
  type AIContext,
  type SuggestionResponse,
  type Suggestion,
} from '@/lib/ai-service';
import { checkQuota, incrementQuota } from '@/lib/quota';
import { logInfo, logError } from '@/lib/logger';
import { logRequestHistory, getClientInfo } from '@/lib/request-history';
import { apiRateLimiter } from '@/lib/rate-limiter';

const generateSchema = z.object({
  text: z.string().min(1, 'Text is required'),
  context: z
    .object({
      appName: z.string().optional(),
      fieldType: z.string().optional(),
      textLength: z.number(),
      language: z.string().optional().default('en'),
    })
    .optional(),
  maxSuggestions: z.number().min(1).max(10).optional().default(5),
});

export async function POST(request: NextRequest) {
  const startTime = Date.now();
  let userId: string | undefined;
  let statusCode = 200;

  try {
    // Apply rate limiting
    const rateLimitResult = await apiRateLimiter(request);
    if ('status' in rateLimitResult) {
      return rateLimitResult;
    }

    // Authenticate the user
    const authResult = await authenticate(request);
    if ('status' in authResult) {
      return authResult;
    }

    const { user } = authResult;
    userId = user.id;

    // Check quota
    const quotaCheck = await checkQuota(userId);
    if (!quotaCheck.allowed) {
      statusCode = 429;
      logInfo('Quota exceeded', { userId, remaining: quotaCheck.remaining });

      const response = NextResponse.json(
        {
          error: 'Daily quota exceeded',
          quota: {
            limit: quotaCheck.quota,
            remaining: quotaCheck.remaining,
            resetAt: quotaCheck.resetAt,
          },
        },
        { status: 429, headers: rateLimitResult.headers }
      );

      await logRequestHistory({
        userId,
        endpoint: '/api/suggestions/generate',
        method: 'POST',
        statusCode: 429,
        processingTime: Date.now() - startTime,
        ...getClientInfo(request),
      });

      return response;
    }

    // Parse and validate request body
    const body = await request.json();
    const validation = generateSchema.safeParse(body);

    if (!validation.success) {
      statusCode = 400;
      return NextResponse.json(
        { error: 'Validation error', details: validation.error.errors },
        { status: 400 }
      );
    }

    const { text, context, maxSuggestions } = validation.data;

    logInfo('Generating AI suggestions', {
      userId,
      textLength: text.length,
      maxSuggestions,
    });

    // Build context-aware prompt
    let contextInfo = '';
    if (context) {
      if (context.appName) {
        contextInfo += `The user is typing in ${context.appName}. `;
      }
      if (context.fieldType) {
        contextInfo += `Field type: ${context.fieldType}. `;
      }
    }

    const systemPrompt = `You are an expert writing assistant that provides intelligent suggestions to improve text quality.
${contextInfo}
Analyze the given text and provide up to ${maxSuggestions} specific suggestions for improvement.

For each suggestion, identify the type (grammar, style, clarity, tone, spelling, or conciseness), the original phrase, your suggested improvement, the reason for the change, and a confidence score (0-1).

Respond ONLY with a valid JSON array of suggestions in this exact format:
[
  {
    "type": "grammar",
    "original": "the exact phrase from the text",
    "suggestion": "the improved version",
    "reason": "brief explanation why",
    "confidence": 0.95
  }
]

If no improvements are needed, return an empty array: []`;

    const userPrompt = `Analyze this text and provide suggestions:\n\n"${text}"`;

    // Call OpenAI API
    const openai = getOpenAIClient();
    const completion = await openai.chat.completions.create({
      model: AI_CONFIG.model,
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt },
      ],
      temperature: AI_CONFIG.temperature,
      max_tokens: AI_CONFIG.maxTokens,
    });

    const responseText = completion.choices[0]?.message?.content || '[]';

    // Parse suggestions
    let suggestions: Suggestion[] = [];
    try {
      const parsed = JSON.parse(responseText);
      suggestions = Array.isArray(parsed) ? parsed.slice(0, maxSuggestions) : [];
    } catch (error) {
      console.error('Failed to parse AI response:', error);
      console.error('Response was:', responseText);
    }

    const processingTime = Date.now() - startTime;

    // Increment quota
    await incrementQuota(userId!);

    logInfo('AI suggestions generated', {
      userId,
      suggestionsCount: suggestions.length,
      processingTime,
    });

    const response: SuggestionResponse = {
      suggestions,
      processingTime,
    };

    // Log request history
    await logRequestHistory({
      userId: userId!,
      endpoint: '/api/suggestions/generate',
      method: 'POST',
      statusCode: 200,
      processingTime,
      requestData: { textLength: text.length, maxSuggestions },
      responseData: { suggestionsCount: suggestions.length },
      ...getClientInfo(request),
    });

    return NextResponse.json(response, { headers: rateLimitResult.headers });
  } catch (error: any) {
    statusCode = error.code === 'insufficient_quota' ? 429 : 500;

    logError({
      error,
      userId,
      endpoint: '/api/suggestions/generate',
      message: 'Generate suggestions error',
    });

    if (userId) {
      await logRequestHistory({
        userId,
        endpoint: '/api/suggestions/generate',
        method: 'POST',
        statusCode,
        processingTime: Date.now() - startTime,
        ...getClientInfo(request),
      });
    }

    if (error.code === 'insufficient_quota') {
      return NextResponse.json(
        { error: 'AI service quota exceeded' },
        { status: 429 }
      );
    }

    if (error.message?.includes('API key')) {
      return NextResponse.json(
        { error: 'AI service not configured' },
        { status: 500 }
      );
    }

    return NextResponse.json(
      { error: 'Internal server error', message: error.message },
      { status: 500 }
    );
  }
}
