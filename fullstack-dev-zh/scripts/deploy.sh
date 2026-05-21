#!/bin/bash
# 服务器部署脚本
# Usage: bash deploy.sh

set -e

echo "=== 开始部署 ==="

# 加载环境变量
if [ -f .env.production ]; then
    export $(grep -v '^#' .env.production | xargs)
fi

# 拉取最新代码
echo "拉取最新代码..."
git pull origin main

# 构建并启动
echo "构建并启动服务..."
docker compose build --no-cache
docker compose up -d

# 清理旧镜像
echo "清理旧镜像..."
docker image prune -f

# 健康检查
echo "健康检查..."
sleep 10
if curl -sf http://localhost/api/v1/health > /dev/null; then
    echo "=== 部署成功! ==="
else
    echo "健康检查失败，请查看日志: docker compose logs backend"
    exit 1
fi
