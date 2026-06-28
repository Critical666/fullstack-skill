# 独立开发技术文档（产品经理 + 全栈开发）
## 前言

这个项目是我根据我平时的开发习惯，开发的full stack Skill, 主要包含了从产品设计到前后端的开发流程。readme文档中包含了具体的文字说明。

## 设计阶段

### 1. 场景梳理

这一步的目的，是将存在于脑海里的构想，变为可以用自然语言描述的具体场景。
因为自然语言是思维的边界，而且大模型接收的输入，也以自然语言为主，这一步相当重要。

### 1.1 具体步骤

画三个流程图（这一步可以简单点，主要是帮助自己梳理产品思路）
1. 主流程：用户最理想的路径（比如：登录 -> 浏览商品 -> 商品详情页 -> 点击购买 -> 扫码支付）
2. 异常流程：用户在使用过程中遇到的各种异常情况（比如：支付失败、网络超时、服务器异常等）
3. 特殊流程：用户在使用过程中遇到的特殊情况（比如：用户未登录、用户未授权、用户未支付等）

接下来，从这个流程图中，梳理出下面两个具体的产出（这一步应该做的尽可能详细）
1. 用例图
2. 事件风暴

### 1.2 验收标准

场景梳理阶段完成后，应确保以下交付物齐全，方可进入下一阶段：

1. **三个流程图已完成并自检通过**：
   - 主流程覆盖用户的核心操作路径，无遗漏关键步骤。
   - 异常流程覆盖常见错误场景（网络超时、支付失败、服务器异常等），每种异常有明确的处理方式。
   - 特殊流程覆盖边缘情况（未登录、未授权、空数据等），每种情况有对应的分支逻辑。
2. **用例图已产出**：清晰标注了所有参与者（Actor）及其与系统的交互关系，每个用例有明确的触发条件和前置条件。
3. **事件风暴已产出**：包含命令（Command）、事件（Event）、聚合（Aggregate）、限界上下文（Bounded Context）四个要素，事件链路完整可追溯。

**自检方法**：直接发给 AI，看对方仅凭这三个交付物能否复述出产品的核心逻辑。如果能复述 80% 以上，说明场景梳理到位。

## 2. 前后端功能落地

### 2.1 具体步骤

因为上一阶段的产物是从整体系统的角度出发，而落地到前后端开发，需要进一步拆解。
所以首先，应该从场景梳理阶段的产物中，抽象出前端与后端，然后根据下面的模板，写成设计层面的提示词。

### 2.2 前端设计提示词模板

#### 2.2.1 页面导航

（目的：让AI知道有多少页面）

- **站点地图 (Sitemap)**：
    - `/login` (独立路由，无Header/Footer)
    - `/dashboard` (主布局，含侧边栏)
        - `/dashboard/overview` (首页概览)
        - `/dashboard/orders` (订单列表)
    - `/product/[id]` (动态详情页)
- **全局导航规则**：未登录访问`/dashboard/*`自动重定向至`/login`。

#### 2.2.2 页面跳转与交互逻辑

（目的：让AI理解页面的跳转关系与跳转条件）

- **核心流程：下单闭环**
    1. 用户在 `/product/1` 点击【立即购买】。
    2. **前端逻辑**：校验是否登录 (检查LocalStorage中的Token)。
    3. **分支A (未登录)**：弹出Toast提示“请先登录”，**跳转**至 `/login`，并将当前URL作为`redirect`参数携带。
    4. **分支B (已登录)**：调用后端接口 `POST /api/order`，显示全屏Loading遮罩。
    5. 接口返回成功后，**跳转**至 `/payment` 页面，并自动拉起支付组件。

#### 2.2.3 页面级布局结构

（目的：让AI理解具体页面的布局）

页面的布局架构如下：
```text
+-----------------------------------------------------------+
|  [Header]  Logo + 全局搜索框 (SearchBar) + 用户头像菜单      |
+--------------------+--------------------------------------+
|                    |                                      |
|  [Sidebar]        |  [Main Content Area]                |
|  - 导航菜单项 1    |   +----------------------------+    |
|  - 导航菜单项 2    |   |  Breadcrumb 面包屑导航       |    |
|  - 导航菜单项 3    |   +----------------------------+    |
|                    |   |                            |    |
|                    |   |  [此处插入动态页面内容]      |    |
|                    |   |                            |    |
+--------------------+--------------------------------------+
```

####  2.2.4 前端交互细节

目的：让AI理解具体的交互细节

| 交互区域 | 事件/触发 | 前端处理逻辑 (无需后端参与) | 异常/边界处理 |
| :--- | :--- | :--- | :--- |
| **登录页-手机号输入框** | `onChange` | **实时正则校验**：`/^1[3-9]\d{9}$/`。不符合时，输入框底部显示红色错误文案，【登录按钮】保持禁用态。 | 防抖处理 (Debounce 500ms)，避免频繁触发校验。 |
| **订单列表-状态Tab** | `onClick` | 切换Tab时，**仅修改本地状态**，高亮当前Tab。**不请求接口**，而是重新获取数据。 | 若返回数据为空，展示 `<EmptyState>` 组件，文案为“暂无此类订单”。 |
| **金额输入 (转账页)** | `onBlur` | 失去焦点时，自动格式化：保留两位小数 (如 `1000` -> `1,000.00`)。 | 若输入非数字字符，立即截断并Toast提示“仅支持数字”。 |

#### 2.2.5 前后端契约与 Mock 数据 

目的：规定好前后端沟通的标准

- **API 端点 (Endpoint)**: `GET /api/v1/products?page=1&size=10`
- **请求参数 (Request)**: `{ page: number; size: number; keyword?: string }`
- **响应数据类型 (Response Interface)**:
```typescript
interface Product {
  id: string;
  name: string; // 规则：超过12个字符需在中间添加“...”截断 (如: 超长商品名称显...)
  price: number; // 规则：前端展示除以100，带￥符号
  mainImage: string; // 规则：若图片加载失败，显示默认占位图 `@/assets/placeholder.png`
  status: 'ON_SALE' | 'OUT_OF_STOCK';
}
```
- **初始 Mock 数据**: 请生成一个包含 6 条不同商品的 `mockData` 数组，用于页面初始化渲染。
---

#### 2.2.6 使用方法

**分层交付**：如果项目太大，不要一次性把这个模板全扔进去（AI会丢失注意力）。**建议按页面交付**：先发全局架构让AI牢记，然后针对具体页面（如订单页）发送提示词。

### 2.3 后端设计提示词模板

有趣的是，我发现后端的设计上，提示词倒是不复杂，毕竟后端麻烦的地方在于具体的实现步骤，而这个步骤AI又比较强，导致提示词的难度上，反而是前端比较难。

#### 2.3.1 数据模型

目的：后端要定义数据库存什么

| 实体 | 表名 | 字段 | 说明 |
|------|------|------|------|
| 用户 | users | `id` (UUID, PK)、`phone` (varchar, 唯一索引)、`nickname`、`password_hash` (bcrypt)、`created_at` (timestamp) | |
| 订单 | orders | `id` (雪花ID, PK)、`user_id` (FK → users)、`total_amount` (bigint, 单位：分)、`status` (enum: PENDING/PAID/SHIPPED/CANCELLED)、`expire_at` (timestamp) | 金额禁止用浮点数 |

实体关系：users 与 orders 是一对多关系。订单表中 status 变更必须记录日志（请预留 order_logs 表，但暂不实现）。

#### 2.3.2 API接口契约（要和2.2.5一致）

目的：定义前后端交互的“路标”

| 方法 | 端点 | 功能描述 | 请求入参 | 成功出参 | 权限校验 |
|------|------|----------|----------|----------|----------|
| POST | `/api/v1/order/create` | 创建订单 | `{ productId: string, quantity: int, addressId: string }` | `{ orderId: string, payAmount: int, expireAt: string }` | 需携带 JWT Token (Header: Authorization) |
| GET | `/api/v1/order/detail` | 查询订单详情 | `?orderId=xxx` | `{ id, status, amount, items: [{name, price}], address }` | 需携带 JWT，且只能查询本人订单 |
| PUT | `/api/v1/order/cancel` | 取消订单 | `{ orderId: string }` | `{ result: boolean }` | 校验 Token，且仅允许 PENDING 状态取消 |

#### 2.3.3 核心业务逻辑规则

目的：约束AI,防止AI写出错误的CRUD

规则 1：下单扣库存（事务一致性）
逻辑：创建订单时，必须使用数据库行锁（SELECT FOR UPDATE）或Redis原子递减扣减库存。
异常处理：若库存不足，必须回滚事务，返回错误码 40001，提示“库存不足”。

规则 2：超时自动取消（幂等性处理）
逻辑：创建订单时，向消息队列（如RocketMQ）发送延迟消息（延迟15分钟）。15分钟后系统消费消息，检查订单状态。
边界条件：若消费时订单已支付，则不执行任何操作；若仍为 PENDING，则将其改为 CANCELLED 并回滚库存。

规则 3：敏感字段过滤
逻辑：查询用户信息接口，严禁返回 password_hash 字段。AI生成SQL或ORM查询时，必须使用 @JsonIgnore 或 select 指定特定字段。

#### 2.3.4 异常码与全局拦截规范

目的：后端返回给前端的信息必须统一，方便前端提示用户

请在全局异常拦截器中定义以下映射：
401：Token过期或无效（前端需跳转登录）。
403：无权限访问他人数据（前端需弹窗提示）。
500：系统内部错误（仅返回“系统繁忙”，严禁将堆栈信息暴露给前端）。

## 3. 全栈项目落地提示词模板

那么让AI充分理解了前后端的设计后，就应该用AI来写代码了。

### 3.1 项目结构

本全栈方案采用前后端一体的 **Monorepo** 结构，以 `backend/` 和 `frontend/` 作为顶层划分，配合 `shared/` 实现类型共享。

```text
project-root/
├── backend/                     # 后端 FastAPI 应用
├── frontend/                    # 前端 React + TypeScript 应用
├── shared/                      # 前后端共享资源（可选）
├── scripts/                     # 全栈辅助脚本
├── docker-compose.yml           # 一键启动服务编排
└── README.md
```

### 1.1 后端目录详解 (`backend/`)

后端采用经典的 **Controller-Service-Model** 分层架构，目录结构可视化如下：

```text
backend/
├── app/
│   ├── api/                     # 接口层：HTTP 路由与依赖注入
│   │   ├── v1/
│   │   │   ├── endpoints/       # 具体业务路由文件
│   │   │   └── __init__.py
│   │   └── deps.py              # 依赖项（DB会话、当前用户）
│   │
│   ├── core/                    # 核心配置与基础设施
│   │   ├── config.py            # Pydantic Settings 配置类
│   │   ├── security.py          # JWT 生成、密码哈希验证
│   │   └── database.py          # SQLAlchemy 引擎与连接池
│   │
│   ├── models/                  # 数据模型层：SQLAlchemy ORM 表定义
│   │   ├── knowledge_base.py
│   │   └── user.py
│   │
│   ├── schemas/                 # Pydantic 模型：API 请求/响应结构校验
│   │   ├── knowledge_base.py    # 前后端类型契约的唯一源头
│   │   └── user.py
│   │
│   ├── services/                # 业务逻辑层：核心功能实现
│   │   ├── knowledge_base.py    # 知识库增删改查、向量库同步逻辑
│   │   └── auth.py              # 登录注册、权限校验
│   │
│   ├── utils/                   # 通用工具函数（文件解析、日志等）
│   └── main.py                  # FastAPI 应用入口
│
├── tests/                       # 单元测试与集成测试
├── requirements.txt             # 依赖清单
└── .env.example                 # 环境变量模板
```

| 目录/文件 | 核心职责 | 关键关注点 |
|-----------|----------|------------|
| `app/api/` | **HTTP 入口层**。定义路由、依赖注入、状态码 | 绝不可包含业务逻辑，仅做参数接收与响应返回 |
| `app/schemas/` | **数据形状定义**。Pydantic 模型，负责请求校验与响应过滤 | 前后端契约的唯一源头，变更必须同步前端类型 |
| `app/models/` | **数据库映射**。SQLAlchemy ORM 模型，定义表结构与关系 | 与数据库迁移工具 Alembic 联动 |
| `app/services/` | **核心业务逻辑**。所有复杂操作、事务处理、外部调用均在此层 | 全栈开发中后端 80% 的编码时间都在这里 |
| `app/core/` | **基础设施**。配置管理、数据库连接池、安全组件 | 环境变量读取、JWT 生成与验证 |

### 1.2 前端目录详解 (`frontend/`)

前端采用简洁的 **Layer-based** 分层结构，按功能类型（API、组件、页面等）平铺组织，目录结构可视化如下：

```text
frontend/
├── public/                      # 静态资源（index.html、favicon）
├── src/
│   ├── api/                     # API 接口调用（与后端路由一一对应）
│   │   ├── client.ts            # Axios 实例、请求/响应拦截器
│   │   ├── knowledge.ts         # 知识库相关 API
│   │   └── auth.ts              # 认证相关 API
│   │
│   ├── components/              # 通用可复用 UI 组件
│   │   ├── Button.tsx
│   │   ├── Card.tsx
│   │   ├── Modal.tsx
│   │   └── Layout.tsx
│   │
│   ├── hooks/                   # 自定义 Hooks
│   │   ├── useCreateKB.ts
│   │   └── useAuth.ts
│   │
│   ├── pages/                   # 路由页面组件（与 URL 一一对应）
│   │   ├── HomePage.tsx
│   │   ├── LoginPage.tsx
│   │   └── KnowledgeBasePage.tsx
│   │
│   ├── utils/                   # 工具函数（日期格式化、防抖等）
│   ├── types/                   # 全局 TypeScript 类型定义
│   │   └── api.d.ts             # 由 OpenAPI 自动生成，严禁手动修改
│   ├── App.tsx                  # 根组件
│   └── main.tsx                 # 应用入口
│
├── index.html
├── package.json
├── tsconfig.json                # TypeScript 配置
├── vite.config.ts               # 构建工具配置
└── .env.local                   # 本地环境变量
```

| 目录/文件 | 核心职责 | 关键关注点 |
|-----------|----------|------------|
| `src/api/` | **API 调用层**。封装所有后端接口调用，统一使用 `client.ts` 实例 | 每个后端路由对应一个文件，保持前后端映射关系清晰 |
| `src/components/` | **通用 UI 组件**。按钮、卡片、弹窗等纯展示/交互组件 | 无业务逻辑，可跨页面复用 |
| `src/pages/` | **路由页面**。对应 URL 路径的顶层组件 | 负责数据获取与布局编排，组合 `components/` 和 `hooks/` |
| `src/hooks/` | **业务逻辑封装**。自定义 Hooks，封装状态管理、API 调用 | `api/` 驱动数据获取，`pages/` 驱动 UI 更新 |
| `src/types/` | **TypeScript 类型定义**（由后端 OpenAPI 自动生成） | 开发中**严禁手动修改**此目录 |

---

## 2. 前后端交互的标准写法

前后端通信采用 **Vite Proxy + Axios 实例 + 业务层封装** 三层架构。开发时通过 Vite 代理转发请求，避免跨域问题；生产部署时由 Nginx 反向代理接管。

### 2.1 完整交互链路图

```
浏览器中的页面（localhost:5173）
   │
   │  stages.ts 调用 fetchStages()
   ▼
┌─────────────────────────────────────┐
│  ① API 业务封装层（stages.ts）      │
│  调用 apiClient.get("/stages")      │
│  baseURL = "/api/v1" → /api/v1/stages │
└──────────┬──────────────────────────┘
           │
           ▼
┌─────────────────────────────────────┐
│  ② Axios 实例层（client.ts）        │
│  统一的 baseURL、超时、请求头配置    │
│  （后续可在此添加 Token 拦截器）     │
└──────────┬──────────────────────────┘
           │  HTTP 请求到 localhost:5173
           ▼
┌─────────────────────────────────────┐
│  ③ Vite 代理层（vite.config.ts）    │
│  匹配 /api 前缀                     │
│  转发到 http://localhost:8000       │
└──────────┬──────────────────────────┘
           │  转发到后端
           ▼
┌─────────────────────────────────────┐
│  FastAPI 后端（localhost:8000）      │
│  → 路径匹配 /api/v1/stages          │
│  → Pydantic 校验（schemas/）        │
│  → 数据库查询（models/）            │
│  → 返回 JSON 响应                   │
└─────────────────────────────────────┘
           │
           ▼
   JSON 数据原路返回 → UI 渲染
```

### 2.2 三层前端代码详解

#### 第一层：Vite 代理 —— 解决开发跨域

`frontend/vite.config.ts`：

```typescript
import { defineConfig } from "vite";

export default defineConfig({
  server: {
    port: 5173,                                    // 前端开发服务器端口
    proxy: {
      "/api": {                                     // 匹配所有以 /api 开头的请求
        target: "http://localhost:8000",            // 转发到后端地址
        changeOrigin: true,                         // 修改请求 Host 头为目标地址
      },
    },
  },
});
```

> **生产环境**：不再使用 Vite 代理，而是由 Nginx 处理 `/api/` 路径的反向代理。

#### 第二层：Axios 实例 —— 统一请求配置

`frontend/src/api/client.ts`：

```typescript
import axios from "axios";

const apiClient = axios.create({
  baseURL: "/api/v1",           // 基础路径，后续请求只需写相对路径
  timeout: 30000,               // 30 秒超时
  headers: { "Content-Type": "application/json" },
});

export default apiClient;
```

所有业务 API 文件统一导入此实例，确保请求配置一致。后续如需添加 Token 自动携带、错误全局拦截等，只需在此文件中添加拦截器即可。

#### 第三层：业务 API 封装 —— 按模块组织

`frontend/src/api/stages.ts`：

```typescript
import apiClient from "./client";

// 定义返回数据的 TypeScript 类型
export interface StageListItem {
  id: number;
  slug: string;
  title: string;
  subtitle: string;
  description: string;
  tags: string[];
  order: number;
}

export async function fetchStages(): Promise<StageListItem[]> {
  const res = await apiClient.get<StageListItem[]>("/stages");
  return res.data;   // Axios 的 res.data 才是真正的响应体
}
```

每个后端路由组对应一个 API 文件（如 `stages.ts`、`auth.ts`、`rag.ts`），保持前后端映射关系清晰。

### 2.3 后端代码示例

#### `app/schemas/stage.py` —— 定义数据结构

```python
from pydantic import BaseModel

class StageBase(BaseModel):
    slug: str
    title: str
    description: str = ""
    tags: list[str] = []

class StageList(StageBase):
    id: int
    order: int

    model_config = {"from_attributes": True}
```

#### `app/api/v1/endpoints/stages.py` —— 定义路由

```python
from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.models.stage import Stage
from app.schemas.stage import StageList

router = APIRouter(prefix="/stages", tags=["stages"])

@router.get("", response_model=list[StageList])
async def list_stages(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Stage).order_by(Stage.order))
    stages = result.scalars().all()
    return [
        StageList(
            id=s.id, slug=s.slug, title=s.title,
            description=s.description or "",
            tags=s.tags.split(",") if s.tags else [],
            order=s.order,
        )
        for s in stages
    ]
```

### 2.4 前端页面调用示例

`frontend/src/pages/Home.tsx`：

```tsx
import { useQuery } from "@tanstack/react-query";
import { fetchStages } from "../api/stages";

function Home() {
  const { data: stages, isLoading } = useQuery({
    queryKey: ["stages"],
    queryFn: fetchStages,
  });

  if (isLoading) return <div>加载中...</div>;

  return <div>{stages?.map(stage => <StageCard key={stage.id} stage={stage} />)}</div>;
}
```

### 2.5 关键规范

| 规范项 | 要求 | 原因 |
|--------|------|------|
| **baseURL 使用相对路径** | `client.ts` 中填 `/api/v1`，不填完整 URL | 开发环境由 Vite 代理处理，生产环境由 Nginx 处理，无需修改代码 |
| **API 文件按业务拆分** | 每个后端路由组对应一个 `api/*.ts` 文件 | 保持前后端映射清晰，方便定位 |
| **Axios 实例唯一** | 所有请求必须通过 `client.ts` 导出的实例发送 | 统一配置超时、拦截器、Token 注入 |
| **页面不直接调用 axios** | 页面通过 API 封装文件间接请求 | 解耦：后端接口变更时只需改 API 文件，不影响页面 |
| **错误处理** | 业务错误由 API 层或 React Query 统一处理 | 避免页面重复编写 try-catch |

---

## 3. 开发精力分配指南

在实际的全栈开发中，**80% 的时间集中在以下三个文件夹**，其余目录多为框架性代码或自动生成。

| 优先级 | 目录路径 | 核心工作内容 |
|--------|----------|--------------|
| 🔴 **最高** | `backend/app/services/` | 编写核心业务逻辑：数据库事务、外部 API 调用、复杂计算、权限校验 |
| 🟠 **高** | `frontend/src/pages/` + `hooks/` | 开发页面组件与业务逻辑：组合 UI、管理状态、处理交互 |
| 🟡 **中** | `backend/app/schemas/` & `backend/app/api/` | 定义 API 数据结构、新增路由、参数校验 |
| 🟢 **低** | `backend/app/models/` | 新增数据表或修改字段（需配合 Alembic 迁移） |
| ⚪ **极低** | `frontend/src/components/ui/`、`backend/app/core/` 等 | 复用已有组件，极少改动配置 |

### 3.1 为什么是这几个文件夹？

- **`backend/app/services/`**  
  这里是商业逻辑的**唯一容身之处**。无论是判断用户权限，还是调用 OpenAI 生成摘要，所有复杂的、会变化的东西都沉淀在此。写好这一层，后续更换前端框架或数据库都能平稳过渡。

- **`frontend/src/pages/` + `hooks/` + `api/`**  
  按分层组织代码，职责清晰。`pages/` 负责页面编排，`hooks/` 封装业务逻辑，`api/` 管理后端通信。每一层职责单一，新增功能时仅在对应层中添加文件即可。

- **`backend/app/schemas/` + `api/`**  
  这是前后端协作的**合同书**。虽然代码量不大，但一旦定义清楚，后续联调几乎不会出现字段拼写错误或类型不匹配问题。

### 3.2 建议开发流程

1. **定义接口契约**：在 `schemas/` 中写出 `Create` 和 `Response` 模型。
2. **实现后端业务**：在 `services/` 中完成核心逻辑，并在 `api/` 中挂载路由。
3. **生成前端类型**：运行脚本同步 OpenAPI → TypeScript 类型（详见下方说明）。
4. **开发前端功能**：在 `pages/`、`api/`、`hooks/` 中完成 UI 与交互。
5. **联调验证**：启动 `docker-compose up`，确保流程畅通。

#### 步骤 3 详解：自动生成前端类型

FastAPI 会从 Pydantic Schema 自动生成 OpenAPI JSON 文档（`/openapi.json`），前端通过 `openapi-typescript` 将其转为 TypeScript 类型，保证前后端类型 100% 一致。

**前端安装：**

```bash
cd frontend
pnpm add -D openapi-typescript
```

在 `frontend/package.json` 中添加脚本：

```json
"scripts": {
  "generate-api-types": "npx openapi-typescript http://localhost:8000/openapi.json -o src/types/api.d.ts"
}
```

**后端启动后，在前端执行：**

```bash
pnpm generate-api-types
```

生成的 `src/types/api.d.ts` 内容示例：

```typescript
// 由 openapi-typescript 自动生成
export interface paths {
  "/api/v1/knowledge-bases": {
    post: {
      requestBody: {
        content: { "application/json": { name: string; description?: string } };
      };
      responses: {
        200: { content: { "application/json": { id: string; name: string; status: string; created_at: string } } };
      };
    };
  };
}
```

**前端直接引用自动生成的类型：**

```typescript
import type { paths } from '@/types/api';

// 提取接口的响应类型
type CreateKBResponse = paths['/api/v1/knowledge-bases']['post']['responses']['200']['content']['application/json'];
```

> 每次后端 Schema 变更后，只需重新运行 `pnpm generate-api-types`，前端类型会自动同步，无需手动修改。**此目录禁止手动编辑**。

---

## 4. 项目初始化与构建

本章详细说明如何从零开始搭建一个全栈项目，包括环境准备、后端初始化、前端初始化、Monorepo 集成以及 Docker 编排的首次配置。

### 4.1 环境准备清单

在开始之前，请确保开发机上已安装以下工具：

| 工具 | 最低版本 | 验证命令 | 说明 |
|------|----------|----------|------|
| Python | 3.11+ | `python --version` | 后端运行环境 |
| uv | 0.5+ | `uv --version` | 后端包管理器（替代 pip/poetry） |
| Node.js | 18+ | `node --version` | 前端运行环境 |
| pnpm 或 npm | 9+ | `pnpm --version` | 前端包管理器（推荐 pnpm） |
| Docker | 24+ | `docker --version` | 容器化运行与部署 |
| Docker Compose | v2+ | `docker compose version` | 多容器编排 |

> **关于 uv**：uv 是一个用 Rust 编写的极速 Python 包管理器，支持 `uv init` 初始化项目、`uv add` 添加依赖、`uv sync` 同步依赖，完全兼容 `pip` 生态。

安装 uv：

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
# 或使用 pip
pip install uv
```

### 4.2 初始化后端项目

```bash
# 1. 创建项目根目录
mkdir my-fullstack-app && cd my-fullstack-app

# 2. 使用 uv 初始化后端
uv init --package backend
cd backend
```

> **注意**：`uv init --package backend` 会在 `backend/` 下生成 `pyproject.toml` 和 `src/backend/` 目录。如果你希望使用扁平的 `app/` 目录而非 `src/`，可以手动调整。

### 4.3 初始化前端项目

```bash
# 在项目根目录下执行
cd my-fullstack-app

# 使用 Vite 创建 React + TypeScript 项目
pnpm create vite@latest frontend -- --template react-ts
```

### 4.4 Monorepo 集成

在项目根目录创建统一的 `package.json`，实现一键启动前后端：

```bash
cd my-fullstack-app
pnpm init
```

编辑根目录 `package.json`：

```json
{
  "name": "my-fullstack-app",
  "private": true,
  "scripts": {
    "dev": "concurrently -n backend,frontend -c blue,green \"cd backend && uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000\" \"cd frontend && pnpm dev\"",
    "dev:backend": "cd backend && uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000",
    "dev:frontend": "cd frontend && pnpm dev",
    "build": "cd frontend && pnpm build",
    "lint:backend": "cd backend && uv run ruff check",
    "lint:frontend": "cd frontend && pnpm lint"
  },
  "devDependencies": {
    "concurrently": "^9.1.0"
  }
}
```

安装 `concurrently`：

```bash
pnpm install
```

### 4.5 创建 .gitignore

在项目根目录创建 `.gitignore`：

```gitignore
# Python
__pycache__/
*.py[cod]
*.egg-info/
.venv/
*.egg
dist/

# Node
node_modules/
dist/

# Environment
.env
.env.local
.env.*.local

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Docker
docker-data/

# Alembic
*.pyc
```

### 4.6 Docker Compose 初始配置

在项目根目录创建 `docker-compose.yml`（初始开发版）：

```yaml
version: "3.8"

services:
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile.dev
    ports:
      - "8000:8000"
    volumes:
      - ./backend:/app
    environment:
      - DATABASE_URL=postgresql+asyncpg://postgres:postgres@db:5432/myapp
      - ENVIRONMENT=development
    depends_on:
      db:
        condition: service_healthy

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile.dev
    ports:
      - "5173:5173"
    volumes:
      - ./frontend:/app
    depends_on:
      - backend

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: myapp
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5

volumes:
  pgdata:
```

### 4.7 README 模板

```markdown
# My Fullstack App

基于 React + FastAPI 的全栈应用。

## 技术栈

- **前端**: React 18 + TypeScript + Vite + Ant Design
- **后端**: FastAPI + SQLAlchemy (Async) + PostgreSQL
- **部署**: Docker + Docker Compose

## 快速开始

```bash
# 1. 安装依赖
cd backend && uv sync
cd ../frontend && pnpm install
cd ..

# 2. 配置环境变量
cp backend/.env.example backend/.env
cp frontend/.env.local.example frontend/.env.local

# 3. 启动开发服务器
pnpm dev
```

---

## 5. 打包构建

本章说明如何将前后端项目打包为生产可用的静态产物，为容器化部署做准备。

### 5.1 后端打包

后端 Python 项目不产生传统意义上的"编译产物"，生产运行的实质是：**将源代码与依赖一同打包为 Docker 镜像**。在后端目录创建 `Dockerfile`：

```dockerfile
# backend/Dockerfile
# ---- 构建阶段 ----
FROM python:3.12-slim AS builder

# 安装 uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

WORKDIR /app

# 先复制依赖文件（利用 Docker 缓存）
COPY pyproject.toml .
RUN uv sync --no-dev

# ---- 运行阶段 ----
FROM python:3.12-slim

WORKDIR /app

# 从构建阶段复制虚拟环境
COPY --from=builder /app/.venv /app/.venv
COPY --from=builder /bin/uv /bin/uv

# 复制应用代码
COPY app/ app/
COPY alembic/ alembic/
COPY alembic.ini .

ENV PATH="/app/.venv/bin:$PATH"
ENV PYTHONPATH=/app

EXPOSE 8000

# 健康检查
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD curl -f http://localhost:8000/api/v1/health || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### 5.2 前端打包

```bash
cd frontend

# 生产构建
pnpm build

# 产物输出到 frontend/dist/
ls dist/
# index.html
# assets/
#   index-xxxxx.js
#   index-xxxxx.css
#   vendor-xxxxx.js
#   ...
```

---

## 6. 容器化部署

本章介绍完整的容器化部署方案，包含 Docker 多阶段构建、Nginx 反向代理、数据库持久化、以及 CI/CD 集成示例。

### 6.1 部署架构

```
                                  ┌─────────────┐
                                  │   Nginx      │
                                  │  :80/:443    │
                                  └──────┬──────┘
                                         │
                          ┌──────────────┼──────────────┐
                          │              │              │
                    ┌─────▼─────┐  ┌────▼────┐  ┌──────▼─────┐
                    │  Frontend  │  │ Backend │  │    DB      │
                    │  (Nginx)   │  │(Uvicorn)│  │(PostgreSQL)│
                    │  :3000     │  │  :8000  │  │   :5432    │
                    └───────────┘  └─────────┘  └────────────┘
```

- **Nginx**：接收外部请求，静态文件由 Nginx 直接返回，API 请求反向代理到后端
- **Frontend**：构建产物通过 Nginx 容器提供服务，无需 Node.js 运行时
- **Backend**：Uvicorn 启动 FastAPI 应用
- **DB**：PostgreSQL 16，数据挂载持久卷

### 6.2 Nginx 配置

在项目根目录创建 `nginx/nginx.conf`：

```nginx
server {
    listen 80;
    server_name _;
    client_max_body_size 100M;

    # 前端静态文件
    location / {
        root /usr/share/nginx/html;
        index index.html;
        try_files $uri $uri/ /index.html;
    }

    # API 反向代理
    location /api/ {
        proxy_pass http://backend:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 120s;
    }

    # WebSocket 支持
    location /ws/ {
        proxy_pass http://backend:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

### 6.3 前端部署 Dockerfile

创建 `frontend/Dockerfile`：

```dockerfile
# frontend/Dockerfile

# ---- 构建阶段 ----
FROM node:20-alpine AS builder

WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN corepack enable && pnpm install --frozen-lockfile

COPY . .
RUN corepack enable && pnpm build

# ---- 运行阶段 ----
FROM nginx:stable-alpine

# 复制构建产物
COPY --from=builder /app/dist /usr/share/nginx/html

# 复制 Nginx 配置
COPY --from=builder /app/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

### 6.4 完整 docker-compose.yml

```yaml
version: "3.8"

services:
  backend:
    build:
      context: ./backend
    image: myapp-backend:latest
    environment:
      - ENVIRONMENT=production
      - DATABASE_URL=postgresql+asyncpg://${DB_USER:-postgres}:${DB_PASSWORD:-postgres}@db:5432/${DB_NAME:-myapp}
      - SECRET_KEY=${SECRET_KEY:?SECRET_KEY is required}
      - ALGORITHM=HS256
      - ACCESS_TOKEN_EXPIRE_MINUTES=30
      - BACKEND_CORS_ORIGINS=["https://your-domain.com"]
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped
    networks:
      - app-network
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  frontend:
    build:
      context: ./frontend
    image: myapp-frontend:latest
    depends_on:
      - backend
    restart: unless-stopped
    networks:
      - app-network

  nginx:
    image: nginx:stable-alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro       # SSL 证书挂载
      - certbot-data:/var/www/certbot       # Certbot 验证目录
    depends_on:
      - frontend
      - backend
    restart: unless-stopped
    networks:
      - app-network

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: ${DB_USER:-postgres}
      POSTGRES_PASSWORD: ${DB_PASSWORD:-postgres}
      POSTGRES_DB: ${DB_NAME:-myapp}
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER:-postgres}"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped
    networks:
      - app-network
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

volumes:
  pgdata:
  certbot-data:

networks:
  app-network:
    driver: bridge
```

### 6.5 部署脚本

创建 `scripts/deploy.sh`：

```bash
#!/bin/bash
# 服务器部署脚本

set -e

echo "开始部署..."

# 1. 加载环境变量
if [ -f .env.production ]; then
    export $(grep -v '^#' .env.production | xargs)
fi

# 2. 拉取最新代码
echo "拉取最新代码..."
git pull origin main

# 3. 构建并启动
echo "构建并启动服务..."
docker compose build --no-cache
docker compose up -d

# 4. 清理旧镜像
echo "清理旧镜像..."
docker image prune -f

# 5. 健康检查
echo "健康检查..."
sleep 10
if curl -sf http://localhost/api/v1/health > /dev/null; then
    echo "部署成功！"
else
    echo "健康检查失败，请查看日志：docker compose logs backend"
    exit 1
fi
```

### 6.6 HTTPS 配置（可选）

#### 使用 Certbot 自动获取 SSL 证书

```bash
# 安装 Certbot
sudo apt install certbot python3-certbot-nginx

# 获取证书
sudo certbot --nginx -d your-domain.com

# 证书自动续期
sudo certbot renew --dry-run
```

Docker 环境可使用 `nginx-proxy` + `acme-companion` 实现自动化 HTTPS。

### 6.7 CI/CD 集成示例（GitHub Actions）

在项目根目录创建 `.github/workflows/deploy.yml`：

```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Deploy to Server
        uses: appleboy/ssh-action@v1.0.3
        with:
          host: ${{ secrets.SERVER_HOST }}
          username: ${{ secrets.SERVER_USER }}
          key: ${{ secrets.SERVER_SSH_KEY }}
          script: |
            cd /opt/myapp
            git pull origin main
            docker compose pull
            docker compose up -d --build
            docker image prune -f
```

---

## 7. 最佳实践与常见问题

### 7.1 开发规范

#### Git 提交规范

推荐使用 [Conventional Commits](https://www.conventionalcommits.org/)：

```
feat: 新增用户管理功能
fix: 修复知识库删除时的外键错误
refactor: 重构认证中间件逻辑
docs: 更新 API 文档
chore: 升级 FastAPI 至 0.115.0
```

#### 代码质量工具

```bash
# 后端：使用 ruff 进行 lint 和格式化
cd backend
uv run ruff check .        # 代码检查
uv run ruff format .       # 自动格式化

# 前端：ESLint + Prettier
cd frontend
pnpm lint                  # 代码检查
pnpm format                # 自动格式化
```

#### API 设计规范

| 规范 | 说明 |
|------|------|
| **路径命名** | 使用小写 kebab-case：`/api/v1/knowledge-bases` |
| **复数形式** | 集合资源使用复数：`/api/v1/users` |
| **版本前缀** | 始终包含 API 版本：`/api/v1/...` |
| **HTTP 方法** | GET 查询、POST 创建、PUT 全量更新、PATCH 部分更新、DELETE 删除 |
| **状态码** | 200 成功、201 创建成功、204 删除成功、400 参数错误、401 未认证、403 无权限、404 不存在、422 校验失败、500 服务器错误 |
| **统一响应** | 错误响应结构：`{"detail": "错误描述"}` |
| **分页** | GET 列表支持 `?skip=0&limit=20` 参数，响应包含 `total` 字段 |

### 7.2 常见问题排查

#### Docker 相关问题

| 问题 | 可能原因 | 解决方案 |
|------|----------|----------|
| 容器启动后立即退出 | 启动命令错误或依赖缺失 | `docker compose logs backend` 查看日志 |
| 数据库连接拒绝 | 数据库未就绪 | 添加 `depends_on` + `healthcheck` |
| 前端 404 | Nginx 配置中 `try_files` 缺失 | 确保 `try_files $uri $uri/ /index.html` |
| 跨域错误 | CORS 配置不匹配 | 检查 `BACKEND_CORS_ORIGINS` 和 Nginx 代理头 |
| 端口冲突 | 本地端口已被占用 | 修改 `docker-compose.yml` 中的映射端口 |

#### 后端常见问题

```bash
# 查看 uvicorn 日志
docker compose logs -f backend

# 进入后端容器调试
docker compose exec backend /bin/bash

# 手动运行数据库迁移
docker compose exec backend alembic upgrade head

# 查看数据库
docker compose exec db psql -U postgres -d myapp
```

#### 前端常见问题

```bash
# 检查 API 请求是否正确
# 打开浏览器 DevTools → Network 标签

# 验证 Vite 代理配置
# 确保 proxy 目标指向正确的后端地址

# TypeScript 类型错误
# 检查 @/types/api 是否与后端 Schema 一致
# 运行 npm run generate-api-types 重新生成
```

### 7.3 安全注意事项

```bash
# 1. 生产环境密钥管理
# ❌ 不要将明文密钥放在代码中
SECRET_KEY=my-secret-key  # 错误做法

# ✅ 使用环境变量或密钥管理服务
# 通过 docker compose 或 CI/CD 注入
SECRET_KEY=${SECRET_KEY}

# 2. 生成强密钥
openssl rand -hex 32  # 生成 64 位十六进制密钥

# 3. 数据库安全
# 使用非 root 用户连接数据库
# 限制数据库端口仅允许内部网络访问
# 定期备份数据

# 4. HTTPS 强制
# 生产环境必须启用 HTTPS
# Nginx 配置 HTTP → HTTPS 重定向

# 5. 输入校验
# 后端使用 Pydantic 校验所有输入
# 前端也进行基础校验（双重保障）
```

---

### 附录：常用命令速查（完整版）

| 场景 | 命令 |
|------|------|
| 启动后端开发服务器 | `cd backend && uvicorn app.main:app --reload` |
| 启动前端开发服务器 | `cd frontend && npm run dev` |
| 启动全栈开发环境 | `pnpm dev`（使用 concurrently） |
| 生成前端 API 类型 | `npm run generate-api-types`（需事先配置脚本） |
| 前端生产构建 | `cd frontend && pnpm build` |
| 构建 Docker 镜像 | `docker compose build` |
| 启动容器化服务 | `docker compose up -d` |
| 查看容器日志 | `docker compose logs -f [service]` |
| 停止并清理容器 | `docker compose down -v` |
| 进入容器调试 | `docker compose exec [service] /bin/bash` |
| 部署到服务器 | `bash scripts/deploy.sh` |

---

*文档版本：v2.0*  
*适用框架：React 18 + TypeScript + Vite | FastAPI 0.115+ + Pydantic V2 | uv 0.5+*  
*章节概要：第1-3章 目录结构与开发指南 | 第4章 项目初始化 | 第5章 打包构建 | 第6章 容器化部署 | 第7章 最佳实践*
