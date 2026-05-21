---
name: fullstack-dev
description: This skill should be used when the user needs to create, develop, build, or deploy a React + FastAPI fullstack application. It provides a complete workflow covering project initialization (uv init + Vite), development architecture patterns, production building, and containerized deployment (Docker + Docker Compose). Trigger when users ask to "scaffold a fullstack project", "initialize a React + FastAPI app", "set up a fullstack development environment", "build and deploy a fullstack application", or any similar request involving React + FastAPI + Docker.
---

# Fullstack Dev

## Overview

This skill guides the creation of a complete **React + FastAPI** fullstack application using a **Monorepo** structure. It covers the full lifecycle from project initialization to production deployment. The backend uses **uv** as package manager with a Controller-Service-Model architecture; the frontend uses **Vite + TypeScript** with a Layer-based structure; deployment uses **Docker + Docker Compose** with Nginx reverse proxy.

Refer to the bundled **scripts/**, **references/**, and **assets/** for reusable automation and templates.

## Workflow

### 1. Initialize a New Fullstack Project

When the user asks to scaffold a new fullstack project, use the following workflow:

#### 1.1 环境检查

First check whether the required tools are installed:

```bash
python --version     # Required: 3.11+
uv --version         # Required: 0.5+
node --version       # Required: 18+
pnpm --version       # Required: 9+
```

If any tool is missing, install it. For uv:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

#### 1.2 初始化后端

Create the project directory and initialize the backend:

```bash
mkdir my-fullstack-app && cd my-fullstack-app

# Initialize backend with uv
uv init --package backend
cd backend

# Add core dependencies
uv add "fastapi>=0.115.0" "uvicorn[standard]>=0.32.0" "sqlalchemy[asyncio]>=2.0.36"
uv add "pydantic>=2.10.0" "pydantic-settings>=2.6.0"
uv add "asyncpg>=0.30.0" "aiosqlite>=0.20.0"
uv add "alembic>=1.13.0" "python-jose[cryptography]>=3.3.0" "passlib[bcrypt]>=1.7.4"
uv add "httpx>=0.27.0" "python-multipart>=0.0.12"
uv add --dev "pytest>=8.0.0" "pytest-asyncio>=0.24.0" "ruff>=0.7.0"

# Create directory structure
mkdir -p app/{api/v1/endpoints,core,models,schemas,services,utils}
touch app/__init__.py app/api/__init__.py app/api/v1/__init__.py app/api/v1/endpoints/__init__.py
touch app/core/__init__.py app/models/__init__.py app/schemas/__init__.py
touch app/services/__init__.py app/utils/__init__.py
touch app/main.py app/core/config.py app/core/security.py app/core/database.py
touch .env.example

# Initialize Alembic
uv run alembic init alembic
```

**Important**: The `note` inside a `bash` code block (line 306) must be placed outside the block, not inside it:

````
```bash
uv init --package backend
cd backend
```

> **注意**：`uv init --package backend` 会在 `backend/` 下生成 `pyproject.toml` 和 `src/backend/` 目录。如果你希望使用扁平的 `app/` 目录而非 `src/`，可以手动调整。
````

#### 1.3 初始化前端

From the project root directory, initialize the frontend:

```bash
cd my-fullstack-app

# Create Vite React + TypeScript project
pnpm create vite@latest frontend -- --template react-ts
cd frontend

# Install core dependencies
pnpm add axios@^1.7.0 @tanstack/react-query@^5.62.0 zustand@^5.0.0 antd@^5.22.0 react-router-dom@^7.0.0 @ant-design/icons@^5.5.0
pnpm add -D openapi-typescript @types/node@^22.0.0

# Create directory structure
mkdir -p src/{api,components,hooks,pages,types,utils}
touch src/api/client.ts
```

#### 1.4 Monorepo 集成

Create root `package.json` for unified scripts:

```json
{
  "name": "my-fullstack-app",
  "private": true,
  "scripts": {
    "dev": "concurrently -n backend,frontend -c blue,green \"cd backend && uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000\" \"cd frontend && pnpm dev\"",
    "dev:backend": "cd backend && uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000",
    "dev:frontend": "cd frontend && pnpm dev",
    "build": "cd frontend && pnpm build",
    "generate-api-types": "npx openapi-typescript http://localhost:8000/openapi.json -o src/types/api.d.ts"
  },
  "devDependencies": { "concurrently": "^9.1.0" }
}
```

```bash
pnpm install
```

#### 1.5 .gitignore

```gitignore
__pycache__/ .venv/ *.egg-info/ node_modules/ dist/ .env .env.local .DS_Store
```

### 2. 配置开发环境

#### 2.1 后端环境配置

Create `backend/.env`:

```env
PROJECT_NAME=My Fullstack App
ENVIRONMENT=development
DEBUG=true
DATABASE_URL=sqlite+aiosqlite:///./local.db
SECRET_KEY=dev-secret-key
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
BACKEND_CORS_ORIGINS=["http://localhost:5173","http://localhost:3000"]
```

Key backend files to create:

- **`app/core/config.py`**: Pydantic Settings class reading from `.env`
- **`app/core/database.py`**: Async SQLAlchemy engine with session factory
- **`app/main.py`**: FastAPI app with CORS middleware, lifespan, and health check endpoint
- **`app/api/v1/endpoints/`**: Route files using APIRouter

#### 2.2 前端环境配置

Create `frontend/.env.local`:

```env
VITE_API_BASE_URL=http://localhost:8000/api/v1
```

Configure Vite proxy in `frontend/vite.config.ts`:

```typescript
server: {
  port: 5173,
  proxy: { '/api': { target: 'http://localhost:8000', changeOrigin: true } }
}
```

Key frontend files to create:

- **`src/api/client.ts`**: Axios instance with interceptors (auto-attach token, unified error handling)
- **`src/api/knowledge.ts`**: API call functions for knowledge base endpoints
- **`src/hooks/useCreateKB.ts`**: React Query mutation hook
- **`src/pages/KnowledgeBasePage.tsx`**: Page component combining hooks and UI

**Type generation** - Add to `frontend/package.json`:

```json
"scripts": {
  "generate-api-types": "npx openapi-typescript http://localhost:8000/openapi.json -o src/types/api.d.ts"
}
```

### 3. 项目目录结构

#### 后端结构

```
backend/
├── app/
│   ├── api/v1/endpoints/   # HTTP routes (no business logic)
│   ├── core/               # Config, database, security
│   ├── models/             # SQLAlchemy ORM models
│   ├── schemas/            # Pydantic models (API contract source of truth)
│   ├── services/           # Business logic (35% of dev time)
│   └── main.py             # FastAPI entry point
├── alembic/                # Database migrations
└── .env
```

#### 前端结构

```
frontend/src/
├── api/           # API call functions (one file per backend endpoint group)
├── components/    # Reusable UI components
├── hooks/         # Custom hooks (business logic + data fetching)
├── pages/         # Route pages
├── types/         # Auto-generated TypeScript types (DO NOT manually edit)
└── utils/         # Utility functions
```

### 4. 打包构建

#### 后端 Dockerfile

Create `backend/Dockerfile` with multi-stage build:

1. **Build stage**: Copy `pyproject.toml`, run `uv sync --no-dev`
2. **Run stage**: Copy `.venv` from build stage, copy app code, run uvicorn

```dockerfile
FROM python:3.12-slim AS builder
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv
WORKDIR /app
COPY pyproject.toml .
RUN uv sync --no-dev

FROM python:3.12-slim
WORKDIR /app
COPY --from=builder /app/.venv /app/.venv
COPY app/ app/
ENV PATH="/app/.venv/bin:$PATH" PYTHONPATH=/app
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

#### 前端打包

```bash
cd frontend && pnpm build
# Output: frontend/dist/
```

### 5. 容器化部署

#### 前端部署 Dockerfile

```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN corepack enable && pnpm install --frozen-lockfile
COPY . . && RUN corepack enable && pnpm build

FROM nginx:stable-alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY --from=builder /app/nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
```

#### Nginx 配置

```nginx
server {
    listen 80;
    location / {
        root /usr/share/nginx/html;
        index index.html;
        try_files $uri $uri/ /index.html;
    }
    location /api/ {
        proxy_pass http://backend:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

#### Docker Compose

See `assets/docker-compose.yml` for the full template with backend, frontend (via nginx), and PostgreSQL services.

#### 部署脚本

```bash
scripts/deploy.sh
```

The deploy script:
1. Loads `.env.production`
2. Pulls latest code from git
3. Runs `docker compose build && docker compose up -d`
4. Cleans old images
5. Performs health check

### 6. 最佳实践

- **API 规范**: Use kebab-case paths, plural nouns, version prefix (`/api/v1/`)
- **类型同步**: Always run `pnpm generate-api-types` after backend schema changes
- **错误处理**: Backend uses Pydantic for validation; frontend uses Axios interceptors
- **安全性**: Never commit `.env` files; use `SECRET_KEY=${SECRET_KEY}` for Docker

## Resources

### scripts/

Automation scripts for common tasks:

| Script | Purpose |
|--------|---------|
| `init-backend.sh` | Initialize backend project with uv |
| `init-frontend.sh` | Initialize frontend project with Vite |
| `build.sh` | Build frontend and Docker images |
| `deploy.sh` | Deploy to production server |

### references/

Reference documentation loaded into context as needed:

- `project-structure.md` - Detailed directory structure with explanations
- `best-practices.md` - API design, performance optimization, troubleshooting

### assets/

File templates copied during project initialization:

- `docker-compose.yml` - Production Docker Compose template
- `nginx.conf` - Production Nginx configuration
