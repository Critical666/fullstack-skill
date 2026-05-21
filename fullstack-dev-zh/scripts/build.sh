#!/bin/bash
# 生产构建脚本
# Usage: bash build.sh

set -e

echo "=== 生产构建 ==="

# 前端构建
echo "构建前端..."
cd frontend
pnpm install
pnpm build
echo "前端构建完成: frontend/dist/"

# 后端依赖锁定
echo "锁定后端依赖..."
cd ../backend
uv sync --no-dev
echo "后端依赖已同步"

# Docker 镜像构建
echo "构建 Docker 镜像..."
cd ..
docker compose build

echo "=== 全部构建完成 ==="
echo "运行 docker compose up -d 启动服务"
