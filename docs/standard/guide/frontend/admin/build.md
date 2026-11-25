# 3.1.11 环境变量与构建

## 一、环境文件

```
template/admin/
├── .env                 公共配置（所有模式共享）
├── .env.development     开发
├── .env.production      生产
├── .env.integrated      一体化部署（与后端同域，子路径）
└── .env.analyze         构建体积分析
```

加载规则：`.env` 先加载，再被对应模式的文件覆盖。

### `.env` — 公共

```ini
VITE_APP_TITLE=Madong 极速后台开发框架
VITE_APP_NAMESPACE=madong-single
VITE_APP_STORE_SECURE_KEY=please-replace-me-with-your-own-key
VITE_APP_ICON_OFFLINE=false
```

| 变量 | 说明 |
| --- | --- |
| `VITE_APP_TITLE` | 站点标题 |
| `VITE_APP_NAMESPACE` | 本地存储命名空间，同域多项目隔离用 |
| `VITE_APP_STORE_SECURE_KEY` | Pinia 持久化加密密钥，**生产必须替换** |
| `VITE_APP_ICON_OFFLINE` | 是否使用离线图标（内网部署时开启） |

### `.env.development` — 开发

```ini
VITE_PORT=5777
VITE_BASE=/
VITE_GLOB_API_URL=/adminapi

# Webman Push
VITE_GLOB_ENABLE_WSS=true
VITE_GLOB_WSS_URL=ws://127.0.0.1:3501
VITE_GLOB_WSS_APPKEY=60756ede2a9737a05384aad849e220f8

VITE_NITRO_MOCK=true
VITE_DEVTOOLS=false
VITE_INJECT_APP_LOADING=true
```

| 变量 | 说明 |
| --- | --- |
| `VITE_PORT` | 开发服务端口 |
| `VITE_GLOB_API_URL` | 接口前缀，配合 Vite 代理 |
| `VITE_GLOB_ENABLE_WSS` | 是否启用 WebSocket 推送 |
| `VITE_GLOB_WSS_URL` | 推送服务地址（对应后端 `webman/push`） |
| `VITE_GLOB_WSS_APPKEY` | 推送 AppKey，需与后端 `config/push.php` 一致 |
| `VITE_NITRO_MOCK` | 启用内置 Nitro Mock 服务 |
| `VITE_DEVTOOLS` | Vue DevTools 插件 |
| `VITE_INJECT_APP_LOADING` | 注入首屏 Loading 动画 |

### `.env.production` — 生产

```ini
VITE_BASE=/
VITE_GLOB_API_URL=/adminapi
VITE_COMPRESS=none
VITE_PWA=false
VITE_ROUTER_HISTORY=hash
VITE_INJECT_APP_LOADING=true
VITE_ARCHIVER=false
```

| 变量 | 可选值 | 说明 |
| --- | --- | --- |
| `VITE_BASE` | 路径 | 部署基础路径 |
| `VITE_COMPRESS` | `none` / `gzip` / `brotli` | 构建时生成压缩文件 |
| `VITE_PWA` | `true` / `false` | PWA 支持 |
| `VITE_ROUTER_HISTORY` | `hash` / `history` | 路由模式 |
| `VITE_ARCHIVER` | `true` / `false` | 构建后打包成 `dist.zip` |

> `hash` 模式无需 Nginx 额外配置；改 `history` 必须配 `try_files $uri $uri/ /index.html`。

### `.env.integrated` — 一体化部署

与生产的唯一区别是基础路径：

```ini
VITE_BASE=/admin/
VITE_GLOB_API_URL=/adminapi
VITE_COMPRESS=none
VITE_PWA=false
VITE_ROUTER_HISTORY=hash
VITE_INJECT_APP_LOADING=true
VITE_ARCHIVER=false
```

适用于把 admin 放在后端同域的 `/admin/` 子路径下。

## 二、构建命令

```bash
pnpm build              # 生产构建   → .env.production
pnpm build:integrated   # 一体化构建 → .env.integrated
pnpm build:analyze      # 体积分析   → .env.analyze
pnpm preview            # 本地预览构建产物
```

`build` 脚本已设置 `--max-old-space-size=8192`，避免大项目构建 OOM。

产物输出到 `dist/`。

## 三、Vite 配置

`vite.config.ts` 基于 `build/vite` 的封装：

```ts
export default defineConfig(async () => {
  return {
    application: {},
    vite: {
      plugins: [
        viteVisualFormElementPlusPlugin({ umdPath: VISUAL_FORM_UMD_PATH }),
        ElementPlus({ format: 'esm' }),
      ],
      optimizeDeps: {
        include: ELEMENT_PLUS_STYLE_DEPS,
      },
      resolve: {
        alias: {
          '#': fileURLToPath(new URL('src', import.meta.url)),
          '#lib': fileURLToPath(new URL('lib', import.meta.url)),
        },
      },
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
        watch: {
          ignored: ['**/.dbg/**', '**/tooling/mock/.nitro/**'],
        },
      },
    },
  };
});
```

### 路径别名

| 别名 | 指向 |
| --- | --- |
| `#/` | `src/` |
| `#lib/` | `lib/` |

### Element Plus 样式预构建

`ELEMENT_PLUS_STYLE_DEPS` 显式列出常用组件的样式路径并加入 `optimizeDeps.include`，避免开发时因样式按需加载导致的**页面闪烁与频繁重新预构建**。

新增用到的 Element Plus 组件若出现样式闪烁，可把该组件加进这个数组。

## 四、构建插件

`build/vite/plugins/` 下的能力：

| 插件 | 作用 |
| --- | --- |
| `inject-app-loading` | 注入首屏 Loading（`VITE_INJECT_APP_LOADING`） |
| `archiver` | 构建后打包 zip（`VITE_ARCHIVER`） |
| `nitro-mock` | 内置 Mock 服务（`VITE_NITRO_MOCK`） |
| `vxe-table` | vxe-table 按需加载 |
| `dayjs` | dayjs 语言包按需 |
| `importmap` | CDN importmap |
| `html` / `extra-app-config` | HTML 处理与运行时配置注入 |
| `inject-metadata` / `print` / `license` | 元信息、构建输出美化、License 头 |
| `tailwind-reference` | Tailwind 引用处理 |
| `visual-form` | 可视化表单设计器（UMD，来自 `lib/visual-form/`） |

## 五、部署模板

`build/deploy/` 提供开箱即用的部署文件：

```
build/deploy/
├── Dockerfile
├── nginx.conf
└── build-local-docker-image.sh
```

`nginx.conf` 关键片段：

```nginx
server {
  listen 8080;
  server_name localhost;

  location / {
    root /usr/share/nginx/html;
    try_files $uri $uri/ /index.html;
    index index.html;
    # Enable CORS
    add_header 'Access-Control-Allow-Origin' '*';
    add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
    # ...
  }

  error_page 500 502 503 504 /50x.html;
  location = /50x.html {
    root /usr/share/nginx/html;
  }
}
```

`try_files $uri $uri/ /index.html` 是 SPA 刷新不 404 的关键。

完整部署方案见 [7. 部署](../../deploy/index.md)。

## 六、代码质量

```bash
pnpm typecheck     # vue-tsc 类型检查
pnpm lint          # oxlint 检查
pnpm format        # oxfmt 格式化
pnpm check         # 类型检查 + lint
pnpm test:unit     # vitest 单元测试
```

项目使用 **lefthook** 管理 Git Hooks，提交前自动执行检查。

## 七、构建常见问题

| 现象 | 处理 |
| --- | --- |
| 构建内存溢出 | 调大 `--max-old-space-size` |
| 生产环境刷新 404 | `history` 模式缺 `try_files`，或改用 `hash` |
| 静态资源 404 | `VITE_BASE` 与实际部署路径不一致 |
| 接口 404 | 生产环境 Nginx 未配置 `/adminapi` 反向代理 |
| 组件样式闪烁 | 把该 Element Plus 组件加入 `ELEMENT_PLUS_STYLE_DEPS` |
| 产物体积过大 | `pnpm build:analyze` 分析后按需优化 |
| 持久化数据异常 | 检查 `VITE_APP_STORE_SECURE_KEY` 是否在不同环境间变更过 |

> 下一节：[3.2 web 门户端](../web/index.md)
