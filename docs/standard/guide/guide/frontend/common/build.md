# 环境变量与构建

---

## 一、环境文件

| 文件 | 加载模式 | 命令 |
| --- | --- | --- |
| `.env` | 全部 | — |
| `.env.development` | development | `pnpm dev` |
| `.env.production` | production | `pnpm build` |
| `.env.integrated` | integrated | `pnpm build:integrated` |
| `.env.analyze` | analyze | `pnpm build:analyze` |

加载规则：`.env` 先加载，再被对应模式文件**覆盖**。

---

## 二、环境变量清单

### 2.1 `.env`（通用）

```ini
# 应用标题
VITE_APP_TITLE=Madong 极速后台开发框架

# 应用命名空间，用于缓存、store 等功能的前缀，确保隔离
VITE_APP_NAMESPACE=madong-admin-ele

# 对 store 进行加密的密钥，持久化到 localStorage 时使用
VITE_APP_STORE_SECURE_KEY=please-replace-me-with-your-own-key

# 是否启用离线图标
VITE_APP_ICON_OFFLINE=false
```

| 变量 | 说明 | 多套 UI |
| --- | --- | --- |
| `VITE_APP_TITLE` | 浏览器标题 | 可相同 |
| `VITE_APP_NAMESPACE` | 缓存/Store 前缀 | ⚠️ **必须区分** |
| `VITE_APP_STORE_SECURE_KEY` | 持久化加密密钥 | ⚠️ 建议区分，生产必换 |
| `VITE_APP_ICON_OFFLINE` | 离线图标（内网必开） | 可相同 |

### 2.2 `.env.development`（开发）

```ini
VITE_PORT=5777
VITE_BASE=/
VITE_GLOB_API_URL=/adminapi

VITE_GLOB_ENABLE_WSS=true
VITE_GLOB_WSS_URL=ws://127.0.0.1:3501
VITE_GLOB_WSS_APPKEY=60756ede2a9737a05384aad849e220f8

VITE_NITRO_MOCK=true
VITE_DEVTOOLS=false
VITE_INJECT_APP_LOADING=true
```

| 变量 | 说明 |
| --- | --- |
| `VITE_PORT` | 开发端口（多套 UI 需区分） |
| `VITE_BASE` | 部署基础路径 |
| `VITE_GLOB_API_URL` | 接口前缀 |
| `VITE_GLOB_ENABLE_WSS` | 是否启用 WebSocket |
| `VITE_GLOB_WSS_URL` | Webman Push 地址 |
| `VITE_GLOB_WSS_APPKEY` | Push 应用密钥 |
| `VITE_NITRO_MOCK` | Mock 服务开关 |
| `VITE_DEVTOOLS` | Vue DevTools |
| `VITE_INJECT_APP_LOADING` | 注入首屏 Loading |

### 2.3 生产环境额外变量

```ini
VITE_BASE=/
VITE_GLOB_API_URL=https://api.example.com/adminapi
VITE_COMPRESS=gzip                # 压缩方式：gzip | brotli | none
VITE_PWA=false                    # PWA 支持
VITE_VISUALIZER=false             # 打包分析
VITE_ARCHIVER=false               # 产物打包为压缩文件
```

### 2.4 使用方式

```ts
// 直接读取
import.meta.env.VITE_APP_TITLE;

// 通过 useAppConfig（推荐，带类型与默认值处理）
import { useAppConfig } from '#/core/...';

const { apiURL } = useAppConfig(import.meta.env, import.meta.env.PROD);
```

> ⚠️ 只有 `VITE_` 前缀的变量会被注入客户端。**切勿把密钥、Token 等敏感信息放入 `VITE_` 变量**，它们会被打进产物明文可见。

---

## 三、Vite 配置

`vite.config.ts` 关键部分：

### 3.1 路径别名

```ts
resolve: {
  alias: {
    '#': fileURLToPath(new URL('src', import.meta.url)),
    '#lib': fileURLToPath(new URL('lib', import.meta.url)),
  },
}
```

### 3.2 开发代理

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
  watch: {
    ignored: ['**/.dbg/**', '**/tooling/mock/.nitro/**'],
  },
}
```

### 3.3 UI 库按需引入（Element Plus）

```ts
import ElementPlus from 'unplugin-element-plus/vite';

const ELEMENT_PLUS_STYLE_DEPS = [
  'button', 'card', 'checkbox', 'checkbox-button', 'checkbox-group',
  'config-provider', 'date-picker', 'divider', 'image', 'input',
  'input-number', 'loading', 'message', 'notification', 'radio',
  'radio-button', 'radio-group', 'segmented', 'select-v2', 'space',
  'switch', 'table', 'time-picker', 'tree-select', 'upload',
].map((c) => `element-plus/es/components/${c}/style/css`);

plugins: [ ElementPlus({ format: 'esm' }) ],
optimizeDeps: { include: ELEMENT_PLUS_STYLE_DEPS },
```

> 📌 **多套 UI**：这段是 Element Plus 专属，换库时整体替换。详见 [新增一套 UI 指南](./add-new-ui.md)。

### 3.4 可视化表单插件

```ts
viteVisualFormElementPlusPlugin({ umdPath: VISUAL_FORM_UMD_PATH })
// lib/visual-form/designer.umd.js
```

---

## 四、构建命令

| 命令 | 说明 |
| --- | --- |
| `pnpm dev` | 开发服务 |
| `pnpm build` | 生产构建 |
| `pnpm build:integrated` | 集成环境构建 |
| `pnpm build:analyze` | 构建 + 体积分析 |
| `pnpm build:docker` | Docker 镜像构建 |
| `pnpm preview` | 本地预览产物 |

### 4.1 内存配置

```json
"build": "NODE_OPTIONS=--max-old-space-size=8192 vite build --mode production"
```

大型项目构建需较大内存。若构建时报 OOM，可继续调高该值。

### 4.2 产物结构

```
dist/
├── index.html
├── assets/
│   ├── index-[hash].js
│   ├── index-[hash].css
│   └── ...
└── （public/ 下的文件原样拷贝）
```

---

## 五、代码质量命令

| 命令 | 说明 |
| --- | --- |
| `pnpm lint` | Lint 检查（`vsh lint`） |
| `pnpm format` | 自动格式化 |
| `pnpm typecheck` | 类型检查（`vue-tsc --noEmit`） |
| `pnpm check` | typecheck + lint |
| `pnpm test:unit` | 单元测试（Vitest） |
| `pnpm commit` | 规范化提交（czg） |

### 5.1 工具链

| 工具 | 配置文件 | 作用 |
| --- | --- | --- |
| Oxlint | `oxlint.config.ts` | 高性能 Lint（Rust 实现） |
| Oxfmt | `oxfmt.config.ts` | 格式化 |
| ESLint | `eslint.config.mjs` | 补充规则 |
| Stylelint | `stylelint.config.mjs` | 样式检查 |
| vue-tsc | `tsconfig.json` | 类型检查 |
| Lefthook | `lefthook.yml` | Git Hooks |
| Vitest | `vitest.config.ts` | 单元测试 |

### 5.2 Git Hooks

Lefthook 在提交时自动执行 Lint 与格式化。提交信息需符合 Conventional Commits：

```
feat: 新增商品分类模块
fix: 修复列表分页参数丢失
docs: 补充适配层文档
refactor: 重构请求拦截器
style: 格式化代码
test: 补充权限单元测试
chore: 升级依赖
```

推荐使用 `pnpm commit` 交互式生成。

---

## 六、依赖管理

### 6.1 pnpm catalog

版本集中在 `pnpm-workspace.yaml` 定义：

```yaml
catalog:
  vue: ^3.5.0
  element-plus: ^2.8.0
  axios: ^1.7.0
```

`package.json` 中引用：

```json
{
  "dependencies": {
    "vue": "catalog:",
    "element-plus": "catalog:"
  }
}
```

**好处**：多包共享同一版本，升级只改一处。

### 6.2 强制 pnpm

```json
"preinstall": "npx only-allow pnpm",
"engines": { "node": "^22.18.0 || ^24.0.0", "pnpm": ">=10.0.0" },
"packageManager": "pnpm@10.33.4"
```

### 6.3 常用操作

```bash
pnpm install                  # 安装
pnpm add <pkg>                # 添加依赖
pnpm add -D <pkg>             # 添加开发依赖
pnpm remove <pkg>             # 移除
pnpm update --interactive     # 交互式升级
pnpm store prune              # 清理缓存
```

---

## 七、性能优化

### 7.1 构建优化

| 手段 | 配置 |
| --- | --- |
| 产物压缩 | `VITE_COMPRESS=gzip`（`vite-plugin-compression`） |
| UI 库按需引入 | `unplugin-element-plus` |
| 依赖预构建 | `optimizeDeps.include` |
| 代码分割 | Vite 默认 + 路由懒加载 |
| 体积分析 | `pnpm build:analyze`（`rollup-plugin-visualizer`） |

### 7.2 运行时优化

| 手段 | 做法 |
| --- | --- |
| 路由懒加载 | `component: () => import('...')` |
| 组件异步加载 | `defineAsyncComponent()` |
| 大表格虚拟滚动 | VXE Table 内置 |
| 图标离线化 | `VITE_APP_ICON_OFFLINE=true` |
| 语言包按需加载 | `locales/loader/` |
| PWA 缓存 | `VITE_PWA=true` |

### 7.3 分析产物

```bash
pnpm build:analyze
```

生成可视化报告，重点关注：

- 单个 chunk 是否过大（> 500KB 需拆分）
- 是否有重复依赖
- UI 库是否真正按需引入

---

## 八、多环境部署

### 8.1 同域名部署（推荐）

```
https://example.com/           → 前端静态资源
https://example.com/adminapi/  → Nginx 反代到后端 8500
```

```ini
VITE_BASE=/
VITE_GLOB_API_URL=/adminapi
```

### 8.2 子路径部署

```ini
VITE_BASE=/admin/
VITE_GLOB_API_URL=/adminapi
```

### 8.3 跨域部署

```ini
VITE_GLOB_API_URL=https://api.example.com/adminapi
```

需后端配置 CORS。

### 8.4 多套 UI 并存部署

```
https://example.com/ele/     → admin-ele  产物
https://example.com/antd/    → admin-antd 产物
```

各自的 `.env.production`：

```ini
# admin-ele
VITE_BASE=/ele/
VITE_APP_NAMESPACE=madong-admin-ele

# admin-antd
VITE_BASE=/antd/
VITE_APP_NAMESPACE=madong-admin-antd
```

> ⚠️ **命名空间必须不同**，否则 localStorage 冲突导致登录态互相覆盖。

---

## 九、常见问题

**Q：构建时内存溢出（OOM）**
A：调高 `NODE_OPTIONS=--max-old-space-size=8192`。

**Q：生产环境接口 404**
A：检查 `VITE_GLOB_API_URL` 与 Nginx 代理规则是否匹配。

**Q：部署到子路径后资源 404**
A：`VITE_BASE` 需与实际路径一致（含首尾斜杠）。

**Q：图标不显示**
A：内网环境需 `VITE_APP_ICON_OFFLINE=true`。

**Q：改了 `.env` 不生效**
A：Vite 环境变量在启动时读取，需重启开发服务。

**Q：多套 UI 部署后登录互相踢下线**
A：`VITE_APP_NAMESPACE` 未区分。

**Q：`pnpm install` 报 catalog 解析失败**
A：确认在正确的工作区根目录执行，`pnpm-workspace.yaml` 存在。

---

## 十、下一步

- [新增一套 UI 指南](./add-new-ui.md)
- [部署 → 生产部署](../../deploy/production.md)
- [部署 → Nginx 配置](../../deploy/nginx.md)
