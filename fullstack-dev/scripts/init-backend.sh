#!/bin/bash
# 初始化 FastAPI 后端项目
# Usage: bash init-backend.sh <project-directory>

set -e

PROJECT_DIR="${1:-.}"

echo "=== 初始化 FastAPI 后端 ==="

# 创建项目目录
mkdir -p "$PROJECT_DIR" && cd "$PROJECT_DIR"

# 初始化 uv 项目
uv init --package backend
cd backend

# 添加依赖
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

# 初始化 Alembic
uv run alembic init alembic

# 创建 .env.example
cat > .env.example << 'EOF'
PROJECT_NAME=FastAPI App
ENVIRONMENT=development
DEBUG=true
DATABASE_URL=sqlite+aiosqlite:///./local.db
SECRET_KEY=change-me
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
BACKEND_CORS_ORIGINS=["http://localhost:5173"]
EOF

echo "✅ 后端初始化完成: $(pwd)"
