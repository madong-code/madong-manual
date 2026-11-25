# 快速开始

本章帮助你在 **30 分钟内**跑通 Madong 极速后台开发框架的本地开发环境。

---

## 一、总体流程

```
① 环境准备        PHP 8.2+ / Node 22+ / MySQL / Redis / Composer / pnpm
        ↓
② 后端启动        composer install → 配置 .env → php windows.bat / start.php
        ↓
③ 前端启动        pnpm install → pnpm dev
        ↓
④ 初始化安装      访问安装引导，建库建表、创建管理员
        ↓
⑤ 登录后台        开始开发
```

---

## 二、分步指引

| 步骤 | 文档 | 预计耗时 |
| --- | --- | --- |
| 1. 环境准备 | [环境准备](./environment.md) | 10 min |
| 2. 后端启动 | [后端启动](./backend-setup.md) | 5 min |
| 3. 前端启动 | [前端启动](./frontend-setup.md) | 5 min |
| 4. 初始化安装 | [初始化安装](./installation.md) | 5 min |
| 5. 开发第一个功能 | [第一个功能](./first-feature.md) | 15 min |

---

## 三、极速版（已具备环境）

如果你的机器已装好 PHP 8.2+、Node 22+、MySQL、Redis：

### 3.1 后端

```bash
cd backend

# 1. 安装依赖
composer install

# 2. 复制环境变量模板
cp .example.env .env      # Windows: copy .example.env .env

# 3. 编辑 .env，配置数据库与 Redis
#    DB_DATABASE / DB_USERNAME / DB_PASSWORD / REDIS_HOST ...

# 4. 启动（Linux/macOS）
php start.php start

#    启动（Windows）
windows.bat
```

默认监听端口见 `config/server.php`。

### 3.2 前端（后台管理端）

```bash
cd template/admin

# 1. 安装依赖（必须用 pnpm）
pnpm install

# 2. 启动开发服务
pnpm dev
```

访问 `http://localhost:5777`（端口由 `.env.development` 的 `VITE_PORT` 决定）。

### 3.3 首次安装

首次运行需完成安装引导。若 `backend/install.lock` 已存在，说明已安装过，可直接登录。

详见 [初始化安装](./installation.md)。

---

## 四、关键配置速览

### 4.1 后端环境变量 `backend/.env`

```ini
# 应用环境
APP_ENV=local
APP_DEBUG=false

# 数据库
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=madong
DB_USERNAME=root
DB_PASSWORD=root
DB_PREFIX=md_

# Redis
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
REDIS_PASSWORD=null
REDIS_DB=0

# 队列 Redis
QUEUE_REDIS_HOST=redis://127.0.0.1:6379
QUEUE_REDIS_PORT=6379
QUEUE_REDIS_PASSWORD=null
QUEUE_REDIS_DB=0
QUEUE_REDIS_PREFIX=queue

# 自定义缓存 Redis
CACHE_CUSTOM_REDIS_HOST=127.0.0.1
CACHE_CUSTOM_REDIS_PORT=6379
CACHE_CUSTOM_REDIS_PASSWORD=null
CACHE_CUSTOM_REDIS_DB=0
CACHE_CUSTOM_REDIS_PREFIX=cache_custom

# 功能开关
APP_TASK_ENABLED=false      # 定时任务
CAPTCHA_ENABLED=false       # 图形验证码
CAPTCHA_MODE=session        # 验证码模式
RECYCLE_BIN_ENABLED=true    # 回收站
```

> 💡 本地开发建议：`APP_DEBUG=true`（便于查看错误详情）、`CAPTCHA_ENABLED=false`（免验证码登录）。

### 4.2 前端环境变量

`template/admin/.env`（通用）：

```ini
VITE_APP_TITLE=Madong 极速后台开发框架
VITE_APP_NAMESPACE=madong-admin-ele        # 缓存/store 前缀，多套 UI 需区分
VITE_APP_STORE_SECURE_KEY=please-replace-me-with-your-own-key
VITE_APP_ICON_OFFLINE=false
```

`template/admin/.env.development`（开发环境）：

```ini
VITE_PORT=5777                             # 开发端口
VITE_BASE=/
VITE_GLOB_API_URL=/adminapi                # 接口前缀

# Webman Push（WebSocket）
VITE_GLOB_ENABLE_WSS=true
VITE_GLOB_WSS_URL=ws://127.0.0.1:3501
VITE_GLOB_WSS_APPKEY=60756ede2a9737a05384aad849e220f8

VITE_NITRO_MOCK=true                       # Mock 服务
VITE_DEVTOOLS=false                        # Vue DevTools
VITE_INJECT_APP_LOADING=true               # 全局 Loading
```

> ⚠️ `VITE_APP_NAMESPACE` 在部署多套 UI 时**必须区分**（如 `madong-admin-ele` / `madong-admin-antd`），否则同域名下 localStorage 会互相污染。

---

## 五、常用命令速查

### 后端

```bash
php start.php start          # 启动（前台，Linux/macOS）
php start.php start -d       # 启动（守护进程）
php start.php stop           # 停止
php start.php restart        # 重启
php start.php reload         # 平滑重载
php start.php status         # 查看状态
windows.bat                  # Windows 启动

php webman make:controller X # 生成控制器
php webman plugin:install X  # 安装插件
composer install             # 安装依赖
vendor/bin/phinx migrate     # 执行数据库迁移
vendor/bin/phpunit           # 运行测试
```

### 前端

```bash
pnpm install                 # 安装依赖
pnpm dev                     # 开发（development 模式）
pnpm build                   # 生产构建
pnpm build:integrated        # 集成环境构建
pnpm build:analyze           # 打包体积分析
pnpm preview                 # 预览构建产物
pnpm lint                    # 代码检查
pnpm format                  # 格式化
pnpm typecheck               # 类型检查
pnpm check                   # 类型检查 + Lint
pnpm test:unit               # 单元测试
pnpm commit                  # 规范化提交（czg）
```

---

## 六、遇到问题？

- 环境相关 → [环境准备](./environment.md)
- 后端启动失败 → [FAQ · 后端问题](../faq/backend.md)
- 前端启动失败 → [FAQ · 前端问题](../faq/frontend.md)
- 接口 404 / 跨域 → [FAQ · 部署问题](../faq/deploy.md)

---

## 七、下一步

跑通环境后，建议按角色继续：

- **前端开发** → [前端总览](../frontend/index.md) → [通用规范](../frontend/common/index.md)
- **后端开发** → [后端总览](../backend/index.md) → [分层设计](../backend/architecture/layers.md)
- **想快速产出功能** → [第一个功能](./first-feature.md) → [代码生成器](../plugin/codegen.md)
