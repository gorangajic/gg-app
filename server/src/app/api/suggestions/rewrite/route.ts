import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { authenticate } from '@/lib/middleware';
import {
  getOpenAIClient,
  AI_CONFIG,
  RewriteStyle,
  type RewriteResponse,
} from '@/lib/ai-service';

const rewriteSchema = z.object({
  text: z.string().min(1, 'Text is required'),
  style: z.enum([
    'professional',
    'casual',
    'formal',
    'friendly',
    'concise',
    'creative',
  ]),
});

export async function POST(request: NextRequest) {
  const startTime = Date.now();

  try {
    // Authenticate the user
    const authResult = await authenticate(request);
    if (authResult instanceof NextResponse) {
      return authResult;
    }

    const { user } = authResult;

    // Parse and validate request body
    const body = await request.json();
    const validation = rewriteSchema.safeParse(body);

    if (!validation.success) {
      return NextResponse.json(
        { error: 'Validation error', details: validation.error.errors },
        { status: 400 }
      );
    }

    const { text, style } = validation.data;

    // Style-specific instructions
    const styleInstructions: Record<string, string> = {
      professional:
        'Rewrite in a professional, business-appropriate tone. Use formal language and clear, direct communication.',
      casual:
        'Rewrite in a casual, conversational tone. Use everyday language and a relaxed style.',
      formal:
        'Rewrite in a highly formal, academic tone. Use sophisticated vocabulary and proper grammar.',
      friendly:
        'Rewrite in a warm, friendly tone. Make it personable and approachable while maintaining clarity.',
      concise:
        'Rewrite to be as concise as possible while retaining all essential information. Remove redundancy.',
      creative:
        'Rewrite in a creative, engaging way. Use vivid language and interesting expressions while keeping the core message.',
    };

    const systemPrompt = `You are an expert writing assistant specializing in text rewriting.
${styleInstructions[style]}

Respond with ONLY the rewritten text. Do not include explanations, quotes, or any other text.
Preserve the core meaning and information while adapting the style.`;

    const userPrompt = `Rewrite this text:\n\n"${text}"`;

    // Call OpenAI API
    const openai = getOpenAIClient();
    const completion = await openai.chat.completions.create({
      model: AI_CONFIG.model,
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt },
      ],
      temperature: style === 'creative' ? 0.7 : AI_CONFIG.temperature,
      max_tokens: AI_CONFIG.maxTokens,
    });

    let rewritten = completion.choices[0]?.message?.content || text;

    // Clean up response (remove quotes if AI added them)
    rewritten = rewritten.trim();
    if (
      (rewritten.startsWith('"') && rewritten.endsWith('"')) ||
      (rewritten.startsWith("'") && rewritten.endsWith("'"))
    ) {
      rewritten = rewritten.slice(1, -1);
    }

    const processingTime = Date.now() - startTime;

    // Log usage
    console.log(
      `Text rewrite for user ${user.id}: ${style} style in ${processingTime}ms`
    );

    const response: RewriteResponse = {
      original: text,
      rewritten,
      style: style as RewriteStyle,
      processingTime,
    };

    return NextResponse.json(response);
  } catch (error: any) {
    console.error('Rewrite text error:', error);

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
