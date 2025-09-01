# Claude Code Instructions for Mexican Train

## Project Overview
Mexican Train domino game with FastAPI backend, Next.js frontend, and Docker deployment.

## Development Commands

### Start Development Environment
```bash
docker-compose up --build
```

### Backend Commands (in backend/)
```bash
uv sync                    # Install dependencies
uv run uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload  # Start dev server
uv run pytest            # Run tests
uv run alembic upgrade head  # Run database migrations
```

### Frontend Commands (in frontend/)
```bash
npm install               # Install dependencies
npm run dev              # Start dev server
npm run build            # Build for production
npm run type-check       # TypeScript type checking
npm run lint             # ESLint
```

## Access URLs (Development)
- Frontend: http://localhost:3002
- Backend API: http://localhost:8002
- API Docs: http://localhost:8002/docs
- Full Stack (Nginx): http://localhost:8082
- Database: localhost:5434
- Redis: localhost:6380

## Key Architecture
- **Backend**: FastAPI + SQLAlchemy + WebSockets + Redis
- **Frontend**: Next.js + NextAuth + React + TypeScript + Tailwind
- **Database**: PostgreSQL with Alembic migrations
- **Real-time**: WebSocket game manager for multiplayer
- **AI**: 5 skill levels from "Sleepy Caboose" to "Locomotive Legend"

## Development Workflow
1. Use `docker-compose up --build` for full stack development
2. Backend changes auto-reload via volume mounts
3. Frontend has hot reload enabled
4. Database schema changes via Alembic migrations
5. Test with `uv run pytest` (backend) and `npm test` (frontend)

## Important Notes
- Environment variables in `.env` file
- OAuth credentials need to be configured for social auth
- Guest users get train-themed auto-generated names
- WebSocket connections handle real-time game state