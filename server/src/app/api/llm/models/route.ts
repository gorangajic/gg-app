import { NextRequest, NextResponse } from 'next/server';
import OpenAI from 'openai';
import { authenticate } from '@/lib/middleware';

export async function GET(request: NextRequest) {
  try {
    // Authenticate the user
    const authResult = await authenticate(request);
    if (authResult instanceof NextResponse) {
      return authResult; // Return error response if authentication fails
    }

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

    // Get available models
    const models = await openai.models.list();

    // Filter to only chat models
    const chatModels = models.data.filter((model) =>
      model.id.includes('gpt')
    );

    return NextResponse.json({
      success: true,
      models: chatModels,
    });
  } catch (error: any) {
    console.error('Models list error:', error);
    return NextResponse.json(
      { error: 'Internal server error', message: error.message },
      { status: 500 }
    );
  }
}
