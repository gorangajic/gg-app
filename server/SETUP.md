# Server Setup Guide

Quick guide to get the TypeWise AI server running.

## Prerequisites

- Node.js 18+ and npm
- Docker and Docker Compose (for database)
- OpenAI API key

## Quick Start

### 1. Install Dependencies

```bash
cd server
npm install
```

### 2. Start PostgreSQL Database

Using Docker Compose (recommended):

```bash
docker-compose up -d
```

This starts PostgreSQL on `localhost:5432` with:
- Database: `gg_app`
- User: `ggapp`
- Password: `ggapp_dev_password`

**Verify database is running:**
```bash
docker-compose ps
```

### 3. Configure Environment Variables

A `.env` file has been created with default values. **You must add your OpenAI API key:**

```bash
# Edit .env file
nano .env  # or use your preferred editor

# Find this line and add your key:
OPENAI_API_KEY="sk-your-openai-api-key-here"
```

### 4. Set Up Database Schema

Generate Prisma client and create tables:

```bash
npm run db:generate
npm run db:push
```

You should see:
```
✔ Generated Prisma Client
🚀  Your database is now in sync with your Prisma schema.
```

### 5. Start the Server

```bash
npm run dev
```

Server starts on http://localhost:3001

### 6. Test the Server

Open http://localhost:3001 in your browser. You should see:
- API documentation
- Sign In / Create Account buttons

## Troubleshooting

### Database Connection Error

**Error:** `Can't reach database server at localhost:5432`

**Fix:**
```bash
# Check if Docker container is running
docker-compose ps

# If not running, start it
docker-compose up -d

# Check logs
docker-compose logs postgres
```

### Prisma Client Not Found

**Error:** `Cannot find module '@prisma/client'`

**Fix:**
```bash
npm run db:generate
```

### Port Already in Use

**Error:** `Port 3001 is already in use`

**Fix:**
```bash
# Option 1: Change port in .env
PORT=3002

# Option 2: Kill process using port 3001
lsof -ti:3001 | xargs kill
```

### OpenAI API Errors

**Error:** `OpenAI API key not configured`

**Fix:**
- Add your API key to `.env` file
- Restart the server

## Database Management

### View Data with Prisma Studio

```bash
npm run db:studio
```

Opens GUI at http://localhost:5555 to view/edit database records.

### Reset Database

**Warning:** This deletes all data!

```bash
# Stop server first
npm run db:push --force-reset
```

### Stop Database

```bash
docker-compose down

# To also remove data volumes:
docker-compose down -v
```

## Testing Authentication

### Create a Test User

1. Start the server: `npm run dev`
2. Visit http://localhost:3001/register
3. Create an account
4. Note the token in the URL redirect

### Test API Endpoints

```bash
# Register a user
curl -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123","name":"Test User"}'

# Save the token from response, then test suggestions:
curl -X POST http://localhost:3001/api/suggestions/generate \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{"text":"This are a test","maxSuggestions":5}'
```

## Production Deployment

For production deployment, see the main README.md for:
- Environment variable security
- Database hosting options
- Server deployment platforms
- HTTPS configuration

## Next Steps

Once the server is running:
1. Configure the Mac app to point to your server URL
2. Test the browser authentication flow
3. Start using the AI features!
