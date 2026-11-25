# 2. 安装指南

本章带你把 Madong 完整跑起来。整体分五步：

```
① 获取源码  →  ② 准备环境  →  ③ 启动后端  →  ④ 初始化安装  →  ⑤ 启动前端
  git clone     PHP/MySQL      backend/       install:madong      template/admin
  / 下载命令     Redis/Node                    或 8500/install     template/web
```

## 2.1 阅读顺序

| 步骤 | 章节 | 说明 |
| --- | --- | --- |
| 1 | [2.1 源码获取与下载](source.md) | 仓库地址、命令下载与手动克隆 |
| 2 | [2.2 环境要求](environment.md) | PHP / 扩展 / MySQL / Redis / Node 版本 |
| 3 | [2.3 后端安装](backend.md) | Composer 安装、`.env` 配置、启动进程 |
| 4 | [2.4 前端安装](frontend.md) | admin / web 两端依赖与启动 |
| 5 | [2.5 安装向导](wizard.md) | 建表、初始化数据、创建管理员 |

## 2.2 最短路径（TL;DR）

假设环境已就绪：

```bash
# 1. 获取前端模板源码（在 backend/ 下执行）
cd backend
php webman madong-download:template

# 2. 安装后端依赖并配置 .env（数据库、Redis）
composer install
php windows.php          # Windows
# 或 php start.php start # Linux / macOS

# 3. 初始化安装（二选一）
php webman install:madong            # 命令行
# 或浏览器访问 http://127.0.0.1:8500/install

# 4. 启动前端
cd template/admin && pnpm install && pnpm dev    # http://localhost:5500
cd template/web  && pnpm install && pnpm dev
```

> 服务端源码来自 `madong-admin` 主仓库；前端模板需单独获取，详见 [2.1 源码获取与下载](source.md)。

## 2.3 端口速查

| 服务 | 默认端口 | 来源 |
| --- | --- | --- |
| 后端 HTTP / 安装向导 | **8500** | `backend/config/process.php` → `webman.listen` |
| 调度器 (scheduler) | 2001 | `backend/config/process.php` → `madong-scheduler.listen` |
| WebSocket 推送 | 3501 | `template/admin/.env.development` → `VITE_GLOB_WSS_URL` |
| admin 开发服务 | **5500** | `template/admin/.env.development` → `VITE_PORT` |
| web 开发服务 | 3000 | Nuxt 默认 |
| MySQL | 3306 | `backend/.env` |
| Redis | 6379 | `backend/.env` |

> 下一节：[2.1 源码获取与下载](source.md)
