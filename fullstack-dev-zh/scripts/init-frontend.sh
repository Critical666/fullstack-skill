#!/bin/bash
# 初始化前端 React + TypeScript 项目
# Usage: bash init-frontend.sh <project-directory>

set -e

PROJECT_DIR="${1:-.}"

echo "=== 初始化 React + TypeScript 前端 ==="

cd "$PROJECT_DIR"

# 使用 Vite 创建项目
pnpm create vite@latest frontend -- --template react-ts
cd frontend

# 安装核心依赖
pnpm add axios@^1.7.0 @tanstack/react-query@^5.62.0 zustand@^5.0.0 antd@^5.22.0 react-router-dom@^7.0.0 @ant-design/icons@^5.5.0
pnpm add -D openapi-typescript @types/node@^22.0.0

# 创建目录结构
mkdir -p src/{api,components,hooks,pages,types,utils}
touch src/api/client.ts

# 添加 TypeScript 路径别名
cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "baseUrl": ".",
    "paths": { "@/*": ["src/*"] }
  },
  "include": ["src"]
}
EOF

# 创建 .env.local
echo "VITE_API_BASE_URL=http://localhost:8000/api/v1" > .env.local

# 在 package.json 中添加类型生成脚本
node -e "
const pkg = require('./package.json');
pkg.scripts['generate-api-types'] = 'npx openapi-typescript http://localhost:8000/openapi.json -o src/types/api.d.ts';
require('fs').writeFileSync('package.json', JSON.stringify(pkg, null, 2));
"

echo "✅ 前端初始化完成: $(pwd)"
