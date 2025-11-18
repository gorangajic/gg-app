import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { authenticate } from '@/lib/middleware';
import {
  getOpenAIClient,
  AI_CONFIG,
  type ImprovementResponse,
} from '@/lib/ai-service';

const improveGrammarSchema = z.object({
  text: z.string().min(1, 'Text is required'),
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
    const validation = improveGrammarSchema.safeParse(body);

    if (!validation.success) {
      return NextResponse.json(
        { error: 'Validation error', details: validation.error.errors },
        { status: 400 }
      );
    }

    const { text } = validation.data;

    const systemPrompt = `You are an expert grammar checker and writing improvement assistant.
Analyze the given text and fix any grammatical errors, spelling mistakes, or awkward phrasing while preserving the original meaning and tone.

Respond with a JSON object in this exact format:
{
  "improved": "the corrected text",
  "changes": [
    {
      "type": "grammar|spelling|clarity",
      "original": "the original phrase",
      "corrected": "the corrected phrase",
      "explanation": "brief explanation"
    }
  ]
}

If no changes are needed, return:
{
  "improved": "the original text unchanged",
  "changes": []
}`;

    const userPrompt = `Improve the grammar and clarity of this text:\n\n"${text}"`;

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

    const responseText = completion.choices[0]?.message?.content || '{}';

    // Parse response
    let improved = text;
    let changes: any[] = [];
    try {
      const parsed = JSON.parse(responseText);
      improved = parsed.improved || text;
      changes = parsed.changes || [];
    } catch (error) {
      console.error('Failed to parse AI response:', error);
      console.error('Response was:', responseText);
    }

    const processingTime = Date.now() - startTime;

    // Log usage
    console.log(
      `Grammar improvement for user ${user.id}: ${changes.length} changes in ${processingTime}ms`
    );

    const response: ImprovementResponse = {
      original: text,
      improved,
      changes,
      processingTime,
    };

    return NextResponse.json(response);
  } catch (error: any) {
    console.error('Improve grammar error:', error);

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
