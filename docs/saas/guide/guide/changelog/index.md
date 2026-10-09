# 9 更新日志

> 本文档按版本记录主要变更。升级前请先阅读[升级指南](./upgrade.md)、[部署](../deploy/index.md) 与[二开 - 升级与兼容](../dev-guide/upgrade.md)。

## 版本记录

> 每个版本一个独立文件，命名规律 `v<major>.<minor>.<patch>.md`；`v5.0.md` 额外保留初始版本总览。

- [v5.2.0](./v5.2.0.md) — 2026-09-29：MCP 端点接入、菜单徽标推送、租户编码登录、上传空间隔离、Swow 协程支持
- [v5.1.3](./v5.1.3.md) — 2026-09-02：租户插件体系重构（授权与安装态拆分、生命周期编排、平台分发中心）
- [v5.1.2](./v5.1.2.md) — 2026-08-04：站点配置字段统一、页脚重构、租户时间字段时间戳化、字典索引调整
- [v5.1.1](./v5.1.1.md) — 2026-07-29：内容审核模块、上传存储抽象重构、租户建库幂等优化
- [v5.1.0](./v5.1.0.md) — 2026-07-22：多租户 SaaS 模板体系、安装器与租户隔离增强、Web 前端全量重构
- [v5.0.1](./v5.0.1.md) — 2026-07-01：键值编辑与富文本组件、依赖更新
- [v5.0.0](./v5.0.0.md) — 2026-06-25：文档体系、Web 终端、插件市场、代码生成器
- [v5.0](./v5.0.md) — 初始版本：webman 2.x + ThinkORM + mono 前端 + 插件系统 + 代码生成器

## v5.x（当前标准版）

### 架构

- 后端：PHP 8.2+ / Webman 2.2 / Laravel Illuminate Database 11（非 think-orm）。
- 后台前端：`template/mono/apps/admin`，Vben Admin 5.7 内核（inline `src/core/`），Vue 3 + Element Plus，pnpm monorepo，Node ^22.18 || ^24。
- 平台前端：`template/mono/apps/platform`，Vben Admin 5.7 内核，平台级管理，接口前缀 `/platformapi`。
- 前台前端：`template/web`，Nuxt 4（当前 `ssr: false`，3 种路由模式 frontend/backend/hybrid）。
- 安装向导：`template/mono/apps/install`，轻量 SPA，6 步 + SSE 进度，生成 `install.lock`。

### 后端能力

- 严格四层架构：Controller → Service → Dao → Model（仅向下依赖）。
- OpenAPI 注解路由（`#[OA\...]`），自动生成 `/adminapi/openapi` 文档。
- JWT 鉴权 + `#[Permission(code)]` 注解 + Casbin RBAC 权限体系。
- 通用 `Crud` 控制器（列表/增删改/回收站/导入导出）。
- 内置高级能力：Web 终端（phpseclib + SSE）、应用插件（运行时 `backend/plugin/`）、查询构造器（`madong/query` 的前缀过滤）、消息推送（`MessagePusher` + webman/push WebSocket）、内容审核（可插件扩展类型）。
- Phinx 迁移、Redis 3 连接组、MySQL 表前缀 `md_`。

### 前端能力

- admin：`useCrud` + `CrudSchema` 声明式 CRUD、`BaseService` 请求封装、`CellDictTag`/`ApiDict` 字典渲染、前缀约定、`$t` 国际化、角色/权限路由守卫。
- web：`request`（fetch 默认导出）、`routes.ts` meta、多租户 `X-Tenant-Id`、Token 刷新队列、SSE。

### 工具链

- `skills/` AI 技能库，覆盖后端/前端/主题，支持 CodeBuddy/Cursor/Trae/Copilot 同步。
- 脚手架命令：`madong-make:*`（单文件）、`madong-plugin:*`（插件）、`install:madong` 等。
- 部署模板：admin `nginx.conf` + `Dockerfile`、web `Dockerfile`、Supervisor 配置。

## 升级提示

- 从旧版升级需：读 changelog → 执行迁移 → `composer update` / `pnpm install` → 重新构建前端 → 重启服务。
- 框架核心（`backend/core/`、前端 `packages/scripts/internal`）保持只读，不随业务升级改写。

---

*具体补丁版本与 breaking change 请以 `composer.json` / `package.json` 锁定版本及仓库 tag 为准；跨版本升级步骤见 [升级指南](./upgrade.md)。*
