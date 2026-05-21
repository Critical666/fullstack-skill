# 全栈最佳实践参考

## API 设计规范

| 规范 | 说明 |
|------|------|
| 路径命名 | 小写 kebab-case：`/api/v1/knowledge-bases` |
| 复数形式 | 集合资源使用复数：`/api/v1/users` |
| 版本前缀 | 始终包含：`/api/v1/...` |
| HTTP 方法 | GET 查询、POST 创建、PUT 全量更新、PATCH 部分更新、DELETE 删除 |
| 状态码 | 200 成功、201 创建、204 删除、400 参数错误、401 未认证、403 无权限、404 不存在、422 校验失败、500 服务器错误 |
| 分页 | GET 列表支持 `?skip=0&limit=20`，响应包含 `total` |
| 错误响应 | `{"detail": "错误描述"}` |

## 性能优化

### 后端

```python
# 异步数据库驱动
DATABASE_URL = "postgresql+asyncpg://..."

# 连接池配置
engine = create_async_engine(url, pool_size=20, max_overflow=10, pool_pre_ping=True)

# 避免 N+1 查询
from sqlalchemy.orm import selectinload
query = select(User).options(selectinload(User.posts))

# 字段索引
class User(Base):
    email = Column(String, index=True)
```

### 前端

```typescript
// React Query 缓存
const queryClient = new QueryClient({
  defaultOptions: {
    queries: { staleTime: 5 * 60 * 1000, gcTime: 30 * 60 * 1000 },
  },
});

// 组件懒加载
const HeavyComponent = lazy(() => import('./HeavyComponent'));
<Suspense fallback={<Spin />}><HeavyComponent /></Suspense>
```

## 常见问题排查

### Docker

| 问题 | 解决 |
|------|------|
| 容器启动退出 | `docker compose logs backend` |
| 数据库连接拒绝 | 检查 `depends_on` + `healthcheck` |
| 前端 404 | Nginx 添加 `try_files $uri /index.html` |
| 跨域错误 | 检查 CORS 配置和 Nginx 代理头 |

### 后端

```bash
docker compose exec backend alembic upgrade head
docker compose exec db psql -U postgres -d myapp
```

### 前端

```bash
# 浏览器 DevTools → Network 检查请求
# 验证 Vite 代理配置
# 重新生成类型
pnpm generate-api-types
```

## 安全注意事项

```bash
# 密钥管理
openssl rand -hex 32              # 生成密钥
SECRET_KEY=${SECRET_KEY}          # 通过环境变量注入

# 数据库
# 使用非 root 用户、限制端口、定期备份

# HTTPS
# 生产环境必须启用，Nginx 配置 HTTP → HTTPS 重定向

# 输入校验
# 后端 Pydantic + 前端基础校验
```
