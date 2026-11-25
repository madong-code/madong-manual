# 快速开始

本章帮助你在 **30 分钟内**跑通 Madong 的本地开发环境。完整的安装说明以 [2. 安装指南](../install/index.md) 为准。

---

## 一、总体流程

```
① 获取源码  →  ② 环境准备  →  ③ 后端启动  →  ④ 初始化安装  →  ⑤ 启动前端  →  ⑥ 第一个功能
  下载命令      PHP/MySQL      backend/       install:madong     template/admin    CRUD 示例
                 Redis/Node                    或 8500/install     template/web
```

---

## 二、分步指引

| 步骤 | 文档 | 预计耗时 |
| --- | --- | --- |
| 0. 获取源码 | [2.1 源码获取与下载](../install/source.md) | 5 min |
| 1. 环境准备 | [环境准备](./environment.md) | 10 min |
| 2. 后端启动 | [后端启动](./backend-setup.md) | 5 min |
| 3. 前端启动 | [前端启动](./frontend-setup.md) | 5 min |
| 4. 初始化安装 | [初始化安装](./installation.md) | 5 min |
| 5. 开发第一个功能 | [第一个功能](./first-feature.md) | 15 min |

---

## 三、极速版（已具备环境）

```bash
# 1. 获取前端模板源码（在 backend/ 下执行）
cd backend
php webman madong-download:template

# 2. 安装依赖并配置 backend/.env（数据库、Redis）
composer install
php windows.php          # Windows
# 或 php start.php start # Linux / macOS

# 3. 初始化安装（二选一）
php webman install:madong
# 或浏览器访问 http://127.0.0.1:8500/install

# 4. 启动管理端
cd template/admin && pnpm install && pnpm dev    # http://localhost:5500
```

> 后端主仓库 `madong-admin` 需先克隆到本地；前端模板仓库单独获取，详见 [源码获取与下载](../install/source.md)。
> 仓库中**没有** `.example.env` 和 `windows.bat`，后端 `.env` 已提供默认配置，直接修改即可；Windows 用 `php windows.php` 启动。

---

## 四、关键配置速览

`backend/.env`：

```ini
APP_ENV=local
APP_DEBUG=true
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=madong
DB_USERNAME=root
DB_PASSWORD=root
DB_PREFIX=md_

REDIS_HOST=127.0.0.1
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0

QUEUE_REDIS_HOST=redis://127.0.0.1:6379
APP_TASK_ENABLED=false
CAPTCHA_ENABLED=false
CAPTCHA_MODE=session
RECYCLE_BIN_ENABLED=true
```

> 表前缀 `DB_PREFIX` 安装后不可更改；CLI 安装命令 `install:madong` 默认 `ma_`，请以安装前确定值为准。JWT 密钥由安装向导生成，不要提交真实密钥。

`template/admin/.env.development`：

```ini
VITE_PORT=5500
VITE_ROUTER_HISTORY=hash
VITE_GLOB_API_URL=/adminapi
VITE_GLOB_ENABLE_WSS=true
VITE_GLOB_WSS_URL=ws://127.0.0.1:3501
VITE_NITRO_MOCK=false
```

---

## 五、常用命令速查

### 后端

```bash
php start.php start                   # 启动（Linux/macOS，前台）
php start.php start -d                # 启动（守护进程）
php start.php stop                    # 停止
php start.php restart                 # 重启
php start.php reload                  # 平滑重载
php windows.php                       # Windows 启动
php webman install:madong             # 初始化安装
php webman madong-migrate up          # 数据库迁移
php webman madong-download:template   # 下载前端模板
php webman route:list                 # 查看路由
```

### 前端

```bash
pnpm install                 # 必须使用 pnpm
pnpm dev                     # 开发（development 模式）
pnpm build                   # 生产构建
pnpm build:integrated        # 集成环境构建
pnpm preview                 # 预览构建产物
pnpm lint                    # 代码检查
pnpm typecheck               # 类型检查
pnpm check                   # 类型检查 + Lint
```

---

## 六、遇到问题？

- 环境相关 → [环境准备](./environment.md)
- 后端启动失败 → [2.3 后端安装](../install/backend.md)
- 前端启动失败 → [2.4 前端安装](../install/frontend.md)
- 接口 404 / 跨域 → [FAQ · 部署问题](../faq/deploy.md)

---

## 七、下一步

- **前端开发** → [前端总览](../frontend/index.md)
- **后端开发** → [后端总览](../backend/index.md)
- **想快速产出功能** → [第一个功能](./first-feature.md) → [代码生成器](../dev-guide/codegen.md)
