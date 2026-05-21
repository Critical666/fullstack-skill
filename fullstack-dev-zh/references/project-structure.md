# 全栈项目目录结构参考

## 项目根目录

```
project-root/
├── backend/           # FastAPI 后端应用
├── frontend/          # React + TypeScript 前端应用
├── scripts/           # 全栈辅助脚本
├── nginx/             # Nginx 配置
├── .github/           # CI/CD 配置
├── docker-compose.yml # Docker 服务编排
└── README.md
```

## 后端目录（Controller-Service-Model）

```
backend/
├── app/
│   ├── api/v1/endpoints/   # HTTP 路由（不含业务逻辑）
│   ├── core/               # 配置、数据库连接、安全
│   ├── models/             # SQLAlchemy ORM 表定义
│   ├── schemas/            # Pydantic 请求/响应模型
│   ├── services/           # 业务逻辑（核心开发区域）
│   ├── utils/              # 工具函数
│   └── main.py             # FastAPI 入口
├── alembic/                # 数据库迁移
├── tests/                  # 测试
├── Dockerfile              # 多阶段构建
├── .env                    # 环境变量
└── pyproject.toml          # 依赖管理
```

### 各层职责速查

| 层 | 职责 | 允许的操作 |
|----|------|-----------|
| `endpoints/` | 接收请求、返回响应 | 调用 Service，不做任何业务判断 |
| `schemas/` | 定义数据结构 | 仅 Pydantic 模型，不含方法 |
| `models/` | 数据库表映射 | 仅 ORM 声明，不含业务方法 |
| `services/` | 核心业务逻辑 | 数据库事务、外部调用、权限判断 |
| `core/` | 基础设施 | 配置读取、连接池、JWT 工具 |

### 数据流向

```
HTTP Request → endpoint → schema 校验 → service 调用 → model 查询 → response
```

## 前端目录（Layer-based）

```
frontend/src/
├── api/           # API 调用（每个文件对应一个后端路由组）
├── components/    # 通用 UI 组件
├── hooks/         # 自定义 Hooks（业务逻辑封装）
├── pages/         # 路由页面
├── types/         # OpenAPI 自动生成的类型（严禁手动修改）
└── utils/         # 工具函数
```

### 前端数据流

```
pages → hooks → api → HTTP → Backend
```

## 部署架构

```
Nginx (:80/:443)
  ├── / → frontend（静态文件）
  └── /api/ → backend（反向代理）
                └── PostgreSQL
```
