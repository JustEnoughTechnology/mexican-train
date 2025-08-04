# Mexican Train Domino Game

A web-based Mexican Train domino game with FastAPI backend and React frontend.

## Quick Start

### Prerequisites
- Docker and Docker Compose
- VS Code (optional, for dev container)

### Development Setup

1. **Clone and navigate to project:**
   ```bash
   cd Mexican-Train
   ```

2. **Start the development environment:**
   ```bash
   # Start all services
   docker-compose up --build

   # Or start individual services
   docker-compose up -d db redis
   docker-compose up backend
   docker-compose up frontend
   ```

3. **Access the application:**
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:8000
   - API Docs: http://localhost:8000/docs
   - Nginx (full stack): http://localhost

### VS Code Dev Container

1. Open project in VS Code
2. Install "Dev Containers" extension
3. Press `Ctrl+Shift+P` → "Reopen in Container"
4. VS Code will build and start the development environment

### Architecture

- **Backend**: FastAPI with Python 3.11, PostgreSQL, Redis
- **Frontend**: Next.js 14 with React, TypeScript, Tailwind CSS
- **Package Manager**: uv (faster than pip)
- **Development**: Docker with hot reload
- **Database**: PostgreSQL with SQLAlchemy
- **Real-time**: WebSockets for game communication

### Key Features

- 🎮 Real-time multiplayer gameplay
- 🤖 5 AI skill levels ("Sleepy Caboose" to "Locomotive Legend")
- 🎯 Complete Mexican Train domino rules
- 👥 2-8 players with spectator support
- 🔒 Public/private games with passwords
- ⏱️ Turn time limits
- 📱 Mobile-responsive design

### Development Commands

```bash
# Backend (with uv)
cd backend
uv sync                    # Install dependencies
uv run uvicorn app.main:app --reload  # Start dev server
uv run pytest            # Run tests

# Frontend
cd frontend
npm install               # Install dependencies
npm run dev              # Start dev server
npm run build            # Build for production

# Docker
docker-compose up --build # Build and start all services
docker-compose down       # Stop all services
docker-compose logs backend  # View backend logs
```

### Project Structure

```
Mexican-Train/
├── backend/                 # FastAPI Python backend
│   ├── app/
│   │   ├── api/            # REST API routes
│   │   ├── websockets/     # WebSocket handlers
│   │   ├── game/           # Mexican Train game logic
│   │   ├── ai/             # AI player strategies
│   │   ├── models/         # SQLAlchemy models
│   │   └── core/           # Config, database, auth
│   ├── tests/
│   └── pyproject.toml      # uv dependencies
├── frontend/                # Next.js React app
│   ├── src/
│   │   ├── components/     # UI components
│   │   ├── pages/          # Next.js pages
│   │   ├── hooks/          # Custom React hooks
│   │   ├── stores/         # State management
│   │   └── types/          # TypeScript definitions
│   └── package.json
├── .devcontainer/          # VS Code dev container
├── nginx/                  # Development proxy config
└── docker-compose.yml     # Development services
```

### Next Steps

1. Implement core FastAPI backend (models, auth, game logic)
2. Add WebSocket game communication
3. Build React game components
4. Integrate Mexican Train game engine
5. Add AI player system
6. Create admin dashboard
7. Production deployment configuration

For detailed implementation, see the `.docs/` folder with comprehensive architecture and code examples.