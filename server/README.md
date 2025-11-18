# GG Server

A Next.js TypeScript server application that provides the backend API for TypeWise AI - an intelligent writing assistant. The server handles user authentication, manages AI model interactions, and implements the core writing assistance features.

## Features

- **User Authentication**: JWT-based authentication with session management
- **PostgreSQL Database**: Using Prisma ORM for type-safe database access
- **AI Writing Assistant**: Three core AI-powered features controlled by the server:
  - Generate intelligent writing suggestions (grammar, style, clarity, tone, spelling, conciseness)
  - Improve grammar and fix errors
  - Rewrite text in different styles (professional, casual, formal, friendly, concise, creative)
- **Centralized AI Management**: Server controls OpenAI model selection, temperature, max tokens, and other parameters
- **TypeScript**: Full type safety across the entire application
- **Next.js API Routes**: Modern API route handlers with App Router

## Tech Stack

- **Framework**: Next.js 14 with App Router
- **Language**: TypeScript
- **Database**: PostgreSQL
- **ORM**: Prisma
- **Authentication**: JWT with bcryptjs
- **AI Integration**: OpenAI SDK (GPT-3.5-turbo)

## Prerequisites

- Node.js 18+ and npm
- PostgreSQL database
- OpenAI API key

## Setup

### 1. Install Dependencies

```bash
cd server
npm install
```

### 2. Configure Environment Variables

Copy the example environment file and update with your values:

```bash
cp .env.example .env
```

Edit `.env` and set:
- `DATABASE_URL`: Your PostgreSQL connection string
- `JWT_SECRET`: A strong random secret for JWT signing
- `OPENAI_API_KEY`: Your OpenAI API key
- `AI_MODEL`: (Optional) AI model to use, default: `gpt-3.5-turbo`
- `AI_MAX_TOKENS`: (Optional) Max tokens per request, default: `500`
- `AI_TEMPERATURE`: (Optional) AI temperature, default: `0.3`

### 3. Set Up Database

Generate Prisma client and push the schema to your database:

```bash
npm run db:generate
npm run db:push
```

For production, use migrations instead:

```bash
npm run db:migrate
```

### 4. Run the Server

Development mode:

```bash
npm run dev
```

Production mode:

```bash
npm run build
npm start
```

The server will start on `http://localhost:3001`

## API Endpoints

### Authentication

#### Register a New User

```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securepassword123",
  "name": "John Doe" // optional
}
```

Response:

```json
{
  "message": "User registered successfully",
  "user": {
    "id": "...",
    "email": "user@example.com",
    "name": "John Doe",
    "createdAt": "..."
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

#### Login

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securepassword123"
}
```

Response:

```json
{
  "message": "Login successful",
  "user": {
    "id": "...",
    "email": "user@example.com",
    "name": "John Doe",
    "createdAt": "..."
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

#### Logout

```http
POST /api/auth/logout
Authorization: Bearer <your-token>
```

### AI Writing Assistant

All AI endpoints require authentication via the `Authorization` header.

#### Generate Writing Suggestions

Analyzes text and provides intelligent suggestions for improvement across multiple categories:
- Grammar corrections
- Style improvements
- Clarity enhancements
- Tone adjustments
- Spelling fixes
- Conciseness recommendations

```http
POST /api/suggestions/generate
Authorization: Bearer <your-token>
Content-Type: application/json

{
  "text": "The quick brown fox jump over the lazy dogs.",
  "context": {
    "appName": "Mail",
    "fieldType": "AXTextArea",
    "textLength": 45,
    "language": "en"
  },
  "maxSuggestions": 5
}
```

Response:

```json
{
  "suggestions": [
    {
      "type": "grammar",
      "original": "jump",
      "suggestion": "jumps",
      "reason": "Subject-verb agreement: 'fox' requires the verb 'jumps'",
      "confidence": 0.98
    },
    {
      "type": "grammar",
      "original": "dogs",
      "suggestion": "dog",
      "reason": "Article 'the' suggests singular 'dog' rather than plural",
      "confidence": 0.85
    }
  ],
  "processingTime": 1234
}
```

#### Improve Grammar

Fixes grammatical errors, spelling mistakes, and awkward phrasing while preserving meaning and tone:

```http
POST /api/suggestions/improve-grammar
Authorization: Bearer <your-token>
Content-Type: application/json

{
  "text": "She don't like apples but he do."
}
```

Response:

```json
{
  "original": "She don't like apples but he do.",
  "improved": "She doesn't like apples but he does.",
  "changes": [
    {
      "type": "grammar",
      "original": "don't",
      "corrected": "doesn't",
      "explanation": "Subject-verb agreement with third person singular 'she'"
    },
    {
      "type": "grammar",
      "original": "do",
      "corrected": "does",
      "explanation": "Subject-verb agreement with third person singular 'he'"
    }
  ],
  "processingTime": 987
}
```

#### Rewrite Text

Rewrites text in different styles while preserving the core meaning:

Supported styles:
- `professional` - Business-appropriate, formal language
- `casual` - Conversational, everyday language
- `formal` - Highly formal, academic tone
- `friendly` - Warm, personable, approachable
- `concise` - Removes redundancy, keeps essential information
- `creative` - Engaging, vivid language

```http
POST /api/suggestions/rewrite
Authorization: Bearer <your-token>
Content-Type: application/json

{
  "text": "I think maybe we could possibly consider doing this.",
  "style": "concise"
}
```

Response:

```json
{
  "original": "I think maybe we could possibly consider doing this.",
  "rewritten": "We should do this.",
  "style": "concise",
  "processingTime": 876
}
```

## Architecture

### Server-Controlled AI Configuration

The server centralizes all AI-related configuration, keeping sensitive API keys secure and providing fine-grained control over AI behavior:

- **Model Selection**: Server chooses which OpenAI model to use
- **Token Limits**: Server controls max tokens to manage costs
- **Temperature**: Server sets creativity/consistency level
- **Prompt Engineering**: Server owns all prompts and can A/B test improvements
- **Usage Tracking**: Server logs all AI requests for analytics

### Benefits Over Direct Client Access

1. **Security**: API keys never exposed to clients
2. **Cost Control**: Server enforces token limits and rate limiting
3. **Flexibility**: Change AI providers without updating clients
4. **Analytics**: Track usage patterns and costs
5. **Quality**: Iterate on prompts without client updates
6. **Multi-Provider**: Future support for Anthropic, Google, etc.

## Database Schema

### Users Table

```prisma
model User {
  id        String   @id @default(cuid())
  email     String   @unique
  password  String
  name      String?
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  sessions  Session[]
}
```

### Sessions Table

```prisma
model Session {
  id        String   @id @default(cuid())
  userId    String
  token     String   @unique
  expiresAt DateTime
  createdAt DateTime @default(now())
  user      User     @relation(fields: [userId], references: [id])
}
```

## Development

### Prisma Studio

Open Prisma Studio to view and edit your database:

```bash
npm run db:studio
```

### Database Migrations

Create a new migration:

```bash
npm run db:migrate
```

## Security Considerations

1. **JWT Secret**: Always use a strong, randomly generated secret in production
2. **Password Hashing**: Passwords are hashed with bcryptjs using 10 salt rounds
3. **Session Management**: Sessions expire after 7 days
4. **CORS**: Configure CORS headers appropriately for your frontend
5. **API Keys**: OpenAI API key stored server-side only, never sent to clients
6. **Rate Limiting**: Consider implementing rate limiting for production

## Project Structure

```
server/
├── prisma/
│   └── schema.prisma              # Database schema
├── src/
│   ├── app/
│   │   ├── api/
│   │   │   ├── auth/              # Authentication endpoints
│   │   │   │   ├── register/
│   │   │   │   ├── login/
│   │   │   │   └── logout/
│   │   │   └── suggestions/       # AI writing assistant endpoints
│   │   │       ├── generate/      # Generate suggestions
│   │   │       ├── improve-grammar/ # Improve grammar
│   │   │       └── rewrite/       # Rewrite in different styles
│   │   ├── layout.tsx             # Root layout
│   │   └── page.tsx               # Home page
│   └── lib/
│       ├── ai-service.ts          # AI configuration and types
│       ├── auth.ts                # Authentication utilities
│       ├── middleware.ts          # API middleware
│       └── prisma.ts              # Prisma client
├── .env.example                   # Environment variables template
├── next.config.js                 # Next.js configuration
├── package.json
├── tsconfig.json                  # TypeScript configuration
└── README.md
```

## Mac App Integration

The TypeWise AI Mac app connects to this server instead of calling OpenAI directly:

1. User types in any macOS application
2. Mac app detects typing and captures context (app name, field type, text)
3. Mac app sends authenticated request to server API
4. Server processes request with OpenAI and returns results
5. Mac app displays suggestions in floating overlay

This architecture provides better security, cost control, and flexibility.

## License

Private - Part of GG App Monorepo
