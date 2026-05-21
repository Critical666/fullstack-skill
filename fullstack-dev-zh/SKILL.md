---
name: fullstack-dev-zh
description: 当用户需要创建、开发、构建或部署 React + FastAPI 全栈项目时，应使用此技能。它提供了完整的全栈开发工作流，包括项目初始化（uv init + Vite）、开发架构模式、生产构建和容器化部署（Docker + Docker Compose）。当用户提出"搭建全栈项目"、"创建 React + FastAPI 应用"、"配置全栈开发环境"、"构建并部署全栈应用"或类似的涉及 React + FastAPI + Docker 的请求时触发。
---

# 全栈开发（中文版）

## 概述

本技能指导如何创建一个完整的 **React + FastAPI** 全栈应用，采用 **Monorepo** 结构。覆盖从项目初始化到生产部署的完整生命周期：后端使用 **uv** 管理依赖，采用 Controller-Service-Model 分层架构；前端使用 **Vite + TypeScript**，采用 Layer-based 分层结构；部署使用 **Docker + Docker Compose** + Nginx 反向代理。

请参考 Skill 自带的 **scripts/**（自动化脚本）、**references/**（参考文档）和 **assets/**（模板文件）。

## 工作流程

### 1. 初始化新全栈项目

当用户要求创建一个新的全栈项目时，遵循以下工作流程：

#### 1.1 环境检查

首先检查是否已安装所需工具：

```bash
python --version     # 要求：3.11+
uv --version         # 要求：0.5+
node --version       # 要求：18+
pnpm --version       # 要求：9+
```

如果缺少某个工具，先安装。对于 uv：

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

#### 1.2 初始化后端

创建项目目录并初始化后端：

```bash
mkdir my-fullstack-app && cd my-fullstack-app

# 使用 uv 初始化后端
uv init --package backend
cd backend

# 添加核心依赖
uv add "fastapi>=0.115.0" "uvicorn[standard]>=0.32.0" "sqlalchemy[asyncio]>=2.0.36"
uv add "pydantic>=2.10.0" "pydantic-settings>=2.6.0"
uv add "asyncpg>=0.30.0" "aiosqlite>=0.20.0"
uv add "alembic>=1.13.0" "python-jose[cryptography]>=3.3.0" "passlib[bcrypt]>=1.7.4"
uv add "httpx>=0.27.0" "python-multipart>=0.0.12"
uv add --dev "pytest>=8.0.0" "pytest-asyncio>=0.24.0" "ruff>=0.7.0"

# 创建目录结构
mkdir -p app/{api/v1/endpoints,core,models,schemas,services,utils}
touch app/__init__.py app/api/__init__.py app/api/v1/__init__.py app/api/v1/endpoints/__init__.py
touch app/core/__init__.py app/models/__init__.py app/schemas/__init__.py
touch app/services/__init__.py app/utils/__init__.py
touch app/main.py app/core/config.py app/core/security.py app/core/database.py
touch .env.example

# 初始化 Alembic
uv run alembic init alembic
```

> **注意**：`uv init --package backend` 会在 `backend/` 下生成 `pyproject.toml` 和 `src/backend/` 目录。如果你希望使用扁平的 `app/` 目录而非 `src/`，可以手动调整。

#### 1.3 初始化前端

从项目根目录初始化前端：

```bash
cd my-fullstack-app

# 使用 Vite 创建 React + TypeScript 项目
pnpm create vite@latest frontend -- --template react-ts
cd frontend

# 安装核心依赖
pnpm add axios@^1.7.0 @tanstack/react-query@^5.62.0 zustand@^5.0.0 antd@^5.22.0 react-router-dom@^7.0.0 @ant-design/icons@^5.5.0
pnpm add -D openapi-typescript @types/node@^22.0.0

# 创建目录结构
mkdir -p src/{api,components,hooks,pages,types,utils}
touch src/api/client.ts
```

#### 1.4 Monorepo 集成

创建根目录 `package.json` 统一管理脚本：

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

创建 `backend/.env`：

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

需要创建的核心后端文件：

- **`app/core/config.py`**：Pydantic Settings 配置类，从 `.env` 读取
- **`app/core/database.py`**：异步 SQLAlchemy 引擎 + 会话工厂
- **`app/main.py`**：FastAPI 应用入口，含 CORS、生命周期、健康检查
- **`app/api/v1/endpoints/`**：使用 APIRouter 的路由文件

#### 2.2 前端环境配置

创建 `frontend/.env.local`：

```env
VITE_API_BASE_URL=http://localhost:8000/api/v1
```

在 `frontend/vite.config.ts` 中配置 Vite 代理：

```typescript
server: {
  port: 5173,
  proxy: { '/api': { target: 'http://localhost:8000', changeOrigin: true } }
}
```

需要创建的核心前端文件：

- **`src/api/client.ts`**：Axios 实例，含拦截器（自动携带 Token、统一错误处理）
- **`src/api/knowledge.ts`**：知识库接口的 API 调用函数
- **`src/hooks/useCreateKB.ts`**：React Query 的 mutation Hook
- **`src/pages/KnowledgeBasePage.tsx`**：页面组件，组合 Hooks 和 UI

**类型生成** - 在 `frontend/package.json` 中添加：

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
│   ├── api/v1/endpoints/   # HTTP 路由（不含业务逻辑）
│   ├── core/               # 配置、数据库、安全
│   ├── models/             # SQLAlchemy ORM 模型
│   ├── schemas/            # Pydantic 模型（API 契约唯一来源）
│   ├── services/           # 业务逻辑（35% 开发时间）
│   └── main.py             # FastAPI 入口
├── alembic/                # 数据库迁移
└── .env
```

#### 前端结构

```
frontend/src/
├── api/           # API 调用函数（每个文件对应一个后端路由组）
├── components/    # 可复用的 UI 组件
├── hooks/         # 自定义 Hooks（业务逻辑 + 数据获取）
├── pages/         # 路由页面
├── types/         # 自动生成的 TypeScript 类型（严禁手动编辑）
└── utils/         # 工具函数
```

### 4. 打包构建

#### 后端 Dockerfile

在 `backend/` 下创建 `Dockerfile`，使用多阶段构建：

1. **构建阶段**：复制 `pyproject.toml`，执行 `uv sync --no-dev`
2. **运行阶段**：从构建阶段复制 `.venv`，复制应用代码，运行 uvicorn

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
# 产物输出到 frontend/dist/
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

完整的编排模板参见 `assets/docker-compose.yml`，包含 backend、frontend（通过 Nginx）和 PostgreSQL 服务。

#### 部署脚本

```bash
scripts/deploy.sh
```

部署脚本执行流程：
1. 加载 `.env.production` 环境变量
2. 从 git 拉取最新代码
3. 执行 `docker compose build && docker compose up -d`
4. 清理旧镜像
5. 执行健康检查

### 6. 最佳实践

- **API 规范**：使用小写 kebab-case 路径、复数名词、版本前缀（`/api/v1/`）
- **类型同步**：后端 Schema 变更后，始终运行 `pnpm generate-api-types`
- **错误处理**：后端用 Pydantic 校验；前端用 Axios 拦截器统一处理
- **安全性**：绝不提交 `.env` 文件；Docker 中使用 `SECRET_KEY=${SECRET_KEY}` 注入密钥

## 资源说明

### scripts/（自动化脚本）

| 脚本 | 说明 |
|------|------|
| `init-backend.sh` | 使用 uv 初始化后端项目 |
| `init-frontend.sh` | 使用 Vite 初始化前端项目 |
| `build.sh` | 构建前端产物和 Docker 镜像 |
| `deploy.sh` | 部署到生产服务器 |

### references/（参考文档）

- `project-structure.md` - 详细的目录结构说明
- `best-practices.md` - API 设计规范、性能优化、问题排查

### assets/（模板文件）

- `docker-compose.yml` - 生产环境 Docker Compose 模板
- `nginx.conf` - 生产环境 Nginx 配置
