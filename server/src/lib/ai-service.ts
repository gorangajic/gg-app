import OpenAI from 'openai';

// Initialize OpenAI client
let openaiClient: OpenAI | null = null;

export function getOpenAIClient(): OpenAI {
  if (!openaiClient) {
    if (!process.env.OPENAI_API_KEY) {
      throw new Error('OpenAI API key not configured');
    }
    openaiClient = new OpenAI({
      apiKey: process.env.OPENAI_API_KEY,
    });
  }
  return openaiClient;
}

// AI Configuration controlled by server
export const AI_CONFIG = {
  model: process.env.AI_MODEL || 'gpt-3.5-turbo',
  maxTokens: parseInt(process.env.AI_MAX_TOKENS || '500'),
  temperature: parseFloat(process.env.AI_TEMPERATURE || '0.3'),
} as const;

// Suggestion types
export enum SuggestionType {
  Grammar = 'grammar',
  Style = 'style',
  Clarity = 'clarity',
  Tone = 'tone',
  Spelling = 'spelling',
  Conciseness = 'conciseness',
}

// Rewrite styles
export enum RewriteStyle {
  Professional = 'professional',
  Casual = 'casual',
  Formal = 'formal',
  Friendly = 'friendly',
  Concise = 'concise',
  Creative = 'creative',
}

// AI Context from client
export interface AIContext {
  appName?: string;
  fieldType?: string;
  textLength: number;
  language?: string;
}

// Suggestion response
export interface Suggestion {
  type: SuggestionType;
  original: string;
  suggestion: string;
  reason: string;
  confidence: number;
}

export interface SuggestionResponse {
  suggestions: Suggestion[];
  processingTime: number;
}

// Improvement response
export interface ImprovementResponse {
  original: string;
  improved: string;
  changes: Array<{
    type: string;
    original: string;
    corrected: string;
    explanation: string;
  }>;
  processingTime: number;
}

// Rewrite response
export interface RewriteResponse {
  original: string;
  rewritten: string;
  style: RewriteStyle;
  processingTime: number;
}
