# GG Server

A Next.js TypeScript server application that provides user authentication and LLM proxy services with PostgreSQL database.

## Features

- **User Authentication**: JWT-based authentication with session management
- **PostgreSQL Database**: Using Prisma ORM for type-safe database access
- **LLM Proxy**: Secure proxy to OpenAI API with user authentication
- **TypeScript**: Full type safety across the entire application
- **Next.js API Routes**: Modern API route handlers with App Router

## Tech Stack

- **Framework**: Next.js 14 with App Router
- **Language**: TypeScript
- **Database**: PostgreSQL
- **ORM**: Prisma
- **Authentication**: JWT with bcryptjs
- **LLM Integration**: OpenAI SDK

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

### LLM Proxy

All LLM endpoints require authentication via the `Authorization` header.

#### Chat Completion

```http
POST /api/llm/chat
Authorization: Bearer <your-token>
Content-Type: application/json

{
  "messages": [
    { "role": "user", "content": "Hello, how are you?" }
  ],
  "model": "gpt-4",
  "temperature": 0.7,
  "max_tokens": 1000
}
```

Response:

```json
{
  "success": true,
  "data": {
    "id": "chatcmpl-...",
    "object": "chat.completion",
    "created": 1234567890,
    "model": "gpt-4",
    "choices": [
      {
        "index": 0,
        "message": {
          "role": "assistant",
          "content": "I'm doing well, thank you! How can I help you today?"
        },
        "finish_reason": "stop"
      }
    ]
  }
}
```

#### List Available Models

```http
GET /api/llm/models
Authorization: Bearer <your-token>
```

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
5. **Rate Limiting**: Consider implementing rate limiting for production

## Project Structure

```
server/
├── prisma/
│   └── schema.prisma       # Database schema
├── src/
│   ├── app/
│   │   ├── api/
│   │   │   ├── auth/       # Authentication endpoints
│   │   │   └── llm/        # LLM proxy endpoints
│   │   ├── layout.tsx      # Root layout
│   │   └── page.tsx        # Home page
│   └── lib/
│       ├── auth.ts         # Authentication utilities
│       ├── middleware.ts   # API middleware
│       └── prisma.ts       # Prisma client
├── .env.example            # Environment variables template
├── next.config.js          # Next.js configuration
├── package.json
├── tsconfig.json           # TypeScript configuration
└── README.md
```

## License

Private - Part of GG App Monorepo
