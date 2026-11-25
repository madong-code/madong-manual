# 2.4 前端安装

前端共三个可独立运行的应用，按需启动：

| 应用 | 路径 | 用途 |
| --- | --- | --- |
| admin | `template/admin` | 后台管理端 |
| web | `template/web` | 门户网站端 |
| install | `template/install` | 图形化安装向导 |

三者都强制使用 **pnpm**（`preinstall` 中执行 `npx only-allow pnpm`）。

## 2.4.1 admin 后台端

### 安装依赖

```bash
cd template/admin
pnpm install
```

> `postinstall` 会执行 `pnpm -r run stub`，为工作区内部包生成软链接产物，属正常流程。

### 启动开发服务

```bash
pnpm dev
```

默认地址：**http://localhost:5500**（端口由 `.env.development` 的 `VITE_PORT` 决定）。

### 可用脚本

| 命令 | 说明 |
| --- | --- |
| `pnpm dev` | 开发模式（`vite --mode development`） |
| `pnpm build` | 生产构建（`--mode production`） |
| `pnpm build:integrated` | 一体化部署构建（`--mode integrated`，与后端同域部署） |
| `pnpm build:analyze` | 构建产物体积分析 |
| `pnpm preview` | 本地预览构建产物 |
| `pnpm typecheck` | `vue-tsc` 类型检查 |
| `pnpm lint` / `pnpm format` | 代码检查 / 格式化 |
| `pnpm check` | 类型检查 + lint |
| `pnpm test:unit` | 单元测试（vitest） |

### 开发代理

`vite.config.ts` 中已配置到后端的代理，无需额外处理跨域：

```ts
server: {
  proxy: {
    '/adminapi': {
      changeOrigin: true,
      rewrite: (path) => path.replace(/^\/adminapi/, ''),
      target: 'http://127.0.0.1:8500/adminapi',
      ws: true,
    },
    '/upload': {
      changeOrigin: true,
      target: 'http://127.0.0.1:8500',
    },
  },
},
```

**若后端不在 `127.0.0.1:8500`，请修改这里的 `target`。**

### 环境变量

`.env`（公共）：

```ini
VITE_APP_TITLE=Madong 极速后台开发框架
VITE_APP_NAMESPACE=madong-single          # 缓存/store 前缀，多项目隔离
VITE_APP_STORE_SECURE_KEY=please-replace-me-with-your-own-key   # store 持久化加密密钥
VITE_APP_ICON_OFFLINE=true                # 是否启用离线图标（源码默认值）
```

`.env.development`（开发）：

```ini
VITE_PORT=5500
VITE_BASE=/
VITE_ROUTER_HISTORY=hash                  # hash（默认）| history
VITE_GLOB_API_URL=/adminapi               # 接口前缀

# Webman Push
VITE_GLOB_ENABLE_WSS=true
VITE_GLOB_WSS_URL=ws://127.0.0.1:3501
VITE_GLOB_WSS_APPKEY=60756ede2a9737a05384aad849e220f8

VITE_NITRO_MOCK=false                     # Nitro Mock 服务，默认关闭
VITE_DEVTOOLS=false
VITE_INJECT_APP_LOADING=true
```

`.env.production`（生产）：

```ini
VITE_BASE=/
VITE_GLOB_API_URL=/adminapi
VITE_COMPRESS=none                        # none | brotli | gzip
VITE_PWA=false
VITE_ROUTER_HISTORY=hash                  # hash | history
VITE_INJECT_APP_LOADING=true
VITE_ARCHIVER=false                       # 是否生成 dist.zip
```

> 生产环境请务必修改 `VITE_APP_STORE_SECURE_KEY`。

其余环境文件：`.env.integrated`（一体化部署）、`.env.analyze`（体积分析）。

## 2.4.2 web 门户端

### 安装与启动

```bash
cd template/web
pnpm install
pnpm dev
```

默认地址：**http://localhost:3000**（Nuxt 默认端口）。

### 可用脚本

| 命令 | 说明 |
| --- | --- |
| `pnpm dev` | 开发模式 |
| `pnpm dev:frontend` | 前台路由模式（`NUXT_PUBLIC_ROUTING_MODE=frontend`） |
| `pnpm dev:backend` | 后台路由模式（`NUXT_PUBLIC_ROUTING_MODE=backend`，路由由后端下发） |
| `pnpm build` | 构建 |
| `pnpm build:frontend` / `pnpm build:backend` | 按路由模式构建 |
| `pnpm build:integrated` | 一体化部署构建 |
| `pnpm generate` | 静态站点生成 |
| `pnpm preview` | 预览 |
| `pnpm start` | 运行构建产物（`node .output/server/index.mjs`） |
| `pnpm lint` / `pnpm lint:fix` | 代码检查 |
| `pnpm typecheck` | 类型检查 |

### 路由模式

web 端支持两种路由来源，通过环境变量 `NUXT_PUBLIC_ROUTING_MODE` 切换：

- `frontend` — 使用本地 `src/pages/` 的文件路由
- `backend` — 从后端接口动态获取页面路由（适合 CMS 场景）

详见 [3.2.3 页面与路由](../frontend/web/pages.md)。

## 2.4.3 安装向导入口

在线安装向导由后端提供静态页面，**无需单独启动前端工程**。后端启动后访问 `http://127.0.0.1:8500/install` 即可，详见 [2.5 安装向导](wizard.md)。

## 2.4.4 常见安装问题

| 现象 | 原因与处理 |
| --- | --- |
| `Use "pnpm install" to install` | 使用了 npm/yarn，改用 pnpm |
| Node 版本报错 | 版本不满足 `^22.18.0 \|\| ^24.x`，升级 Node |
| 依赖下载缓慢 | `pnpm config set registry https://registry.npmmirror.com` |
| 接口 404 / 跨域 | 检查后端是否在 `127.0.0.1:8500` 运行，以及 `vite.config.ts` 的 proxy target |
| 构建内存溢出 | `build` 脚本已设置 `--max-old-space-size=8192`，若仍溢出可继续调大 |

> 下一节：[2.5 安装向导](wizard.md)
