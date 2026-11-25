# 1. 介绍

## 1.1 项目概述

**Madong 极速后台开发框架** 是一套基于 **Webman (PHP 8.2+)** + **Vue 3 / Nuxt 4** 的前后端分离中后台开发框架。

仓库由三个可独立运行的部分组成：

| 位置 | 说明 | 技术栈 |
| --- | --- | --- |
| `backend/` | 后端服务，常驻内存的 HTTP / WebSocket 服务 | PHP 8.2+、Webman 2.2、illuminate/database |
| `template/admin/` | 后台管理端（SPA，Vben Admin 5.7 内核） | Vue 3 + Vite + TypeScript + Element Plus |
| `template/web/` | 门户网站端 | Nuxt 4 + Element Plus + UnoCSS |
| `template/install/` | 图形化安装向导 | Vue 3 + Vite |
| `skills/` | 面向 AI 编码助手的开发规约集 | Markdown |
| `docs/` | 本文档（docsify 驱动） | Markdown |

### 设计目标

1. **常驻内存、高性能** —— 基于 Workerman/Webman 的多进程常驻模型，避免传统 PHP-FPM 每次请求重新加载框架的开销。
2. **严格分层** —— `Controller → Service → Dao → Model` 四层职责单一，杜绝业务逻辑散落。
3. **注解驱动路由** —— 路由由 OpenAPI 注解自动派生，接口文档与实现天然同步。
4. **可插拔** —— 前后端均支持插件目录，删除目录即卸载功能，核心不受影响。
5. **多租户就绪** —— 请求链路内置租户上下文，支持 SaaS 场景。
6. **AI 友好** —— `skills/` 目录以结构化规约描述项目约定，可直接被编码助手消费。

## 1.2 适用场景

- 企业内部管理系统、SaaS 多租户后台
- 需要长连接（WebSocket 推送、Web 终端）的运维/监控平台
- 需要门户站 + 管理后台一体化交付的项目

## 1.3 文档导航

| 你想做什么 | 阅读章节 |
| --- | --- |
| 了解框架构成与技术选型 | [1.2 技术栈](tech-stack.md)、[1.3 整体架构](architecture.md) |
| 把项目跑起来 | [2. 安装指南](../install/index.md) |
| 开发后台页面 | [3.1 admin 后台端](../frontend/admin/index.md) |
| 开发门户页面 | [3.2 web 门户端](../frontend/web/index.md) |
| 开发后端接口 | [4. 后端开发](../backend/index.md) |
| 在框架上做二次开发 | [5. 二开指南](../dev-guide/index.md) |
| 上线部署 | [7. 部署](../deploy/index.md) |

## 1.4 版本约定

| 组件 | 版本要求 | 来源 |
| --- | --- | --- |
| PHP | `>= 8.2`（需 `pdo`/`redis`/`gd`/`zip` 扩展） | `backend/composer.json` |
| Node.js | `^22.18.0 \|\| ^24.0.0` | `template/admin/package.json` → `engines` |
| pnpm | `>= 10.0.0`（锁定 `pnpm@10.33.4`） | 同上 `packageManager` |
| Composer | 2.x | — |

> 后端使用 Composer，前端强制使用 pnpm（`preinstall` 中配置了 `only-allow pnpm`）。

> 下一节：[1.2 技术栈](tech-stack.md)
