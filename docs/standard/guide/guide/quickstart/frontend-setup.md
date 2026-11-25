# 前端启动

本页介绍如何启动前端应用。当前主线为后台管理端 `template/admin/`（Element Plus）。

> 前置条件：已完成 [环境准备](./environment.md)，后端已在 `8500` 端口启动。

---

## 一、安装依赖

```bash
cd template/admin
pnpm install
```

> ⚠️ **必须使用 pnpm**。`package.json` 中 `preinstall: npx only-allow pnpm`，使用 npm/yarn 会直接报错退出。

安装慢时切换镜像：

```bash
pnpm config set registry https://registry.npmmirror.com
pnpm install
```

`postinstall` 会自动执行 `pnpm -r run stub --if-present` 构建工作区依赖。

---

## 二、启动开发服务

```bash
pnpm dev
```

等价于 `vite --mode development`，加载 `.env` + `.env.development`。

启动成功后访问：

```
http://localhost:5777
```

端口由 `.env.development` 中 `VITE_PORT=5777` 决定。

---

## 三、环境变量

### 3.1 `.env`（所有环境共用）

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

> 🔑 **多套 UI 必须区分 `VITE_APP_NAMESPACE`**
> 部署多套 UI 到同一域名时，若命名空间相同，localStorage/缓存会互相覆盖。
> 建议：`madong-admin-ele` / `madong-admin-antd` / `madong-admin-naive`。

> 🔒 `VITE_APP_STORE_SECURE_KEY` 生产环境**必须替换**为自有密钥。

### 3.2 `.env.development`（开发环境）

```ini
# 端口号
VITE_PORT=5777

VITE_BASE=/

# 接口地址 - 使用 adminapi 前缀
VITE_GLOB_API_URL=/adminapi

# Webman Push 配置
VITE_GLOB_ENABLE_WSS=true
VITE_GLOB_WSS_URL=ws://127.0.0.1:3501
VITE_GLOB_WSS_APPKEY=60756ede2a9737a05384aad849e220f8

# 是否开启 Nitro Mock 服务，true 为开启，false 为关闭
VITE_NITRO_MOCK=true

# 是否打开 devtools，true 为打开，false 为关闭
VITE_DEVTOOLS=false

# 是否注入全局 loading
VITE_INJECT_APP_LOADING=true
```

### 3.3 环境文件一览

| 文件 | 加载时机 | 用途 |
| --- | --- | --- |
| `.env` | 所有模式 | 通用配置 |
| `.env.development` | `pnpm dev` | 本地开发 |
| `.env.production` | `pnpm build` | 生产构建 |
| `.env.integrated` | `pnpm build:integrated` | 集成环境 |
| `.env.analyze` | `pnpm build:analyze` | 体积分析 |

---

## 四、接口代理

`vite.config.ts` 中已配置开发代理，将前端请求转发到后端 `8500` 端口：

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

**代理规则说明**：

| 前端请求 | 转发到 |
| --- | --- |
| `/adminapi/system/user/list` | `http://127.0.0.1:8500/adminapi/system/user/list` |
| `/upload/xxx.png` | `http://127.0.0.1:8500/upload/xxx.png` |

> 💡 若后端端口不是 `8500`，需同步修改 `vite.config.ts` 中的 `target`。

---

## 五、路径别名

```ts
resolve: {
  alias: {
    '#': fileURLToPath(new URL('src', import.meta.url)),
    '#lib': fileURLToPath(new URL('lib', import.meta.url)),
  },
}
```

| 别名 | 指向 | 示例 |
| --- | --- | --- |
| `#` | `src/` | `import { $t } from '#/core/locales'` |
| `#lib` | `lib/` | `import x from '#lib/visual-form/...'` |

> 项目统一使用 `#/` 而非 `@/`，编写 import 时请注意。

---

## 六、Element Plus 按需加载

`vite.config.ts` 中通过 `unplugin-element-plus` 实现按需引入，并预构建常用组件样式：

```ts
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

> 📌 **多套 UI 提示**：这段配置是 Element Plus 专属，切换到其他 UI 库时需整体替换。详见 [新增一套 UI 指南](../frontend/common/add-new-ui.md)。

此外还注册了可视化表单设计器插件：

```ts
viteVisualFormElementPlusPlugin({ umdPath: VISUAL_FORM_UMD_PATH })
// lib/visual-form/designer.umd.js
```

---

## 七、常用命令

| 命令 | 说明 |
| --- | --- |
| `pnpm dev` | 启动开发服务 |
| `pnpm build` | 生产构建（`NODE_OPTIONS=--max-old-space-size=8192`） |
| `pnpm build:integrated` | 集成环境构建 |
| `pnpm build:analyze` | 构建 + 体积分析 |
| `pnpm build:docker` | 构建 Docker 镜像 |
| `pnpm preview` | 预览构建产物 |
| `pnpm lint` | 代码检查（`vsh lint`） |
| `pnpm format` | 格式化（`vsh lint --format`） |
| `pnpm typecheck` | 类型检查（`vue-tsc --noEmit`） |
| `pnpm check` | 类型检查 + Lint |
| `pnpm test:unit` | 单元测试（Vitest） |
| `pnpm commit` | 规范化提交（czg 交互式） |

---

## 八、其他前端应用

### 8.1 门户端 `template/web/`

```bash
cd template/web
pnpm install
pnpm dev
```

详见 [前端 → 门户端](../frontend/web/index.md)。

### 8.2 安装端 `template/install/`

```bash
cd template/install
pnpm install
pnpm dev
```

详见 [前端 → 安装端](../frontend/install/index.md)。

---

## 九、常见启动问题

**Q：`ERR_PNPM_UNSUPPORTED_ENGINE`**
A：Node 版本不符合 `^22.18.0 || ^24.0.0`，升级 Node 或用 fnm/nvm 切换（项目有 `.node-version`）。

**Q：执行 `npm install` 立即报错**
A：项目强制 pnpm，改用 `pnpm install`。

**Q：端口 5777 被占用**
A：修改 `.env.development` 的 `VITE_PORT`，或结束占用进程。

**Q：接口请求 404 / 无响应**
A：
1. 确认后端已启动且监听 `8500`。
2. 确认 `vite.config.ts` 代理 `target` 与后端端口一致。
3. 确认 `VITE_GLOB_API_URL=/adminapi` 未被改动。

**Q：接口跨域**
A：开发环境走 Vite 代理不应跨域。若跨域说明请求未走代理——检查代码是否写死了完整域名（应使用相对路径 `/adminapi/...`）。

**Q：想用 Mock 数据而非真实后端**
A：设置 `VITE_NITRO_MOCK=true`（默认已开启），Mock 服务位于 `tooling/mock/`。

**Q：页面白屏，控制台报模块解析错误**
A：删除缓存重装：

```bash
rm -rf node_modules .vite dist
pnpm install
```

**Q：类型报错但能正常运行**
A：执行 `pnpm typecheck` 查看完整类型错误；IDE 可能需重启 TS Server。

更多见 [FAQ · 前端问题](../faq/frontend.md)。

---

## 十、下一步

- [初始化安装](./installation.md)
- [前端通用规范](../frontend/common/index.md)
- [Element Plus 分册](../frontend/admin-ele/index.md)
