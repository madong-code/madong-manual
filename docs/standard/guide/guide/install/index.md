# 2. 安装指南

本章带你把 Madong 极速后台开发框架完整跑起来。整体分四步：

```
① 准备环境  →  ② 启动后端  →  ③ 启动前端  →  ④ 运行安装向导
   PHP/MySQL      backend/       template/admin     template/install
   Redis/Node                    template/web
```

## 2.1 阅读顺序

| 步骤 | 章节 | 说明 |
| --- | --- | --- |
| 1 | [2.1 环境要求](environment.md) | PHP / 扩展 / MySQL / Redis / Node 版本 |
| 2 | [2.2 后端安装](backend.md) | Composer 安装、`.env` 配置、启动进程 |
| 3 | [2.3 前端安装](frontend.md) | admin / web / install 三端依赖与启动 |
| 4 | [2.4 安装向导](wizard.md) | 图形化建表、初始化数据、创建管理员 |

## 2.2 最短路径（TL;DR）

假设环境已就绪：

```bash
# 后端
cd backend
composer install
# 编辑 .env 配置数据库与 Redis
php windows.php          # Windows
# 或 php start.php start   # Linux/macOS

# 后台端
cd template/admin
pnpm install
pnpm dev                 # http://localhost:5777

# 门户端
cd template/web
pnpm install
pnpm dev
```

然后访问安装向导完成数据库初始化，详见 [2.4 安装向导](wizard.md)。

## 2.3 端口速查

| 服务 | 默认端口 | 来源 |
| --- | --- | --- |
| 后端 HTTP | **8500** | `backend/config/process.php` → `webman.listen` |
| 调度器 (scheduler) | 2001 | `backend/config/process.php` → `madong-scheduler.listen` |
| WebSocket 推送 | 3501 | `template/admin/.env.development` → `VITE_GLOB_WSS_URL` |
| admin 开发服务 | **5777** | `template/admin/.env.development` → `VITE_PORT` |
| web 开发服务 | 3000 | Nuxt 默认 |
| MySQL | 3306 | `backend/.env` |
| Redis | 6379 | `backend/.env` |

> 下一节：[2.1 环境要求](environment.md)
