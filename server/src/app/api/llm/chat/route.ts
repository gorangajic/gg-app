import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import OpenAI from 'openai';
import { authenticate } from '@/lib/middleware';

const chatSchema = z.object({
  messages: z.array(
    z.object({
      role: z.enum(['user', 'assistant', 'system']),
      content: z.string(),
    })
  ),
  model: z.string().default('gpt-4'),
  temperature: z.number().min(0).max(2).optional(),
  max_tokens: z.number().positive().optional(),
  stream: z.boolean().optional().default(false),
});

export async function POST(request: NextRequest) {
  try {
    // Authenticate the user
    const authResult = await authenticate(request);
    if (authResult instanceof NextResponse) {
      return authResult; // Return error response if authentication fails
    }

    const { user } = authResult;

    // Parse and validate request body
    const body = await request.json();
    const validation = chatSchema.safeParse(body);

    if (!validation.success) {
      return NextResponse.json(
        { error: 'Validation error', details: validation.error.errors },
        { status: 400 }
      );
    }

    const { messages, model, temperature, max_tokens, stream } = validation.data;

    // Check for OpenAI API key
    if (!process.env.OPENAI_API_KEY) {
      return NextResponse.json(
        { error: 'OpenAI API key not configured' },
        { status: 500 }
      );
    }

    // Initialize OpenAI client
    const openai = new OpenAI({
      apiKey: process.env.OPENAI_API_KEY,
    });

    // Make request to OpenAI
    const completion = await openai.chat.completions.create({
      model,
      messages,
      temperature,
      max_tokens,
      stream,
    });

    // Log the request for this user (you can extend this to track usage)
    console.log(`LLM request from user ${user.id} (${user.email})`);

    return NextResponse.json({
      success: true,
      data: completion,
    });
  } catch (error: any) {
    console.error('LLM chat error:', error);

    if (error.code === 'insufficient_quota') {
      return NextResponse.json(
        { error: 'OpenAI API quota exceeded' },
        { status: 429 }
      );
    }

    return NextResponse.json(
      { error: 'Internal server error', message: error.message },
      { status: 500 }
    );
  }
}
