# 3.2.2 目录结构

## 一、项目根目录

```
template/web/
├── src/                 源码（Nuxt srcDir）
├── public/              静态资源，原样拷贝到产物根
├── scripts/             构建/部署脚本
├── nuxt.config.ts       Nuxt 配置
├── uno.config.ts        UnoCSS 配置
├── eslint.config.mjs
├── tsconfig.json
├── Dockerfile
├── .env / .env.development / .env.production / .env.integrated
└── package.json
```

## 二、`src/` 目录

```
src/
├── api/            接口层
├── pages/          页面（文件路由）+ routes.ts 菜单声明
├── layouts/        布局
├── components/     组件
├── composables/    组合式函数
├── stores/         Pinia 状态
├── router/         路由扩展
├── middleware/     路由中间件
├── plugins/        Nuxt 插件（全局）
├── plugin/         可插拔业务插件
├── lang/           语言包
├── assets/         样式与资源（会被构建处理）
├── types/          类型定义
├── utils/          工具函数
├── app.vue         根组件
└── router.options.ts  路由选项（滚动行为等）
```

## 三、各目录职责

### `src/api/` — 接口层

```
api/
├── request.ts      Http 封装类（核心）
├── auth/           登录鉴权
├── member/         会员
├── content/        内容
├── site/           站点配置
└── ...
```

统一从 `~/api/request` 引入：

```ts
import { request } from '~/api/request';

const list = await request.get('/content/article', { params: { page: 1 } });
```

详见 [3.2.4 请求与状态](request.md)。

### `src/pages/` — 页面

Nuxt **文件路由**：文件路径即 URL。

```
pages/
├── index.vue           →  /
├── about/index.vue     →  /about
├── article/
│   ├── index.vue       →  /article
│   └── [id].vue        →  /article/:id
└── routes.ts           菜单声明（非页面）
```

`routes.ts` 是 Madong 极速后台开发框架的扩展，用于**声明菜单结构**（标题、图标、排序、权限码），与文件路由配合工作。详见 [3.2.3 页面与路由](pages.md)。

### `src/layouts/` — 布局

```vue
<!-- layouts/default.vue -->
<template>
  <div class="min-h-screen flex flex-col">
    <AppHeader />
    <main class="flex-1">
      <slot />
    </main>
    <AppFooter />
  </div>
</template>
```

页面中指定布局：

```vue
<script setup lang="ts">
definePageMeta({ layout: 'default' });
</script>
```

### `src/components/` — 组件

Nuxt **自动导入**，无需手动 import：

```
components/
├── AppHeader.vue        →  <AppHeader />
├── AppFooter.vue        →  <AppFooter />
└── common/
    └── Empty.vue        →  <CommonEmpty />
```

嵌套目录会成为组件名前缀。

### `src/composables/` — 组合式函数

同样自动导入：

```ts
// composables/useSiteConfig.ts
export function useSiteConfig() {
  const config = useState('site-config', () => ({}));
  // ...
  return { config };
}
```

```vue
<script setup lang="ts">
// 无需 import
const { config } = useSiteConfig();
</script>
```

### `src/stores/` — Pinia

```ts
// stores/user.ts
export const useUserStore = defineStore('user', {
  state: () => ({ info: null as any }),
  actions: {
    async fetchInfo() {
      this.info = await request.get('/member/info');
    },
  },
  persist: true,   // pinia-plugin-persistedstate
});
```

已注册 `pinia-plugin-persistedstate/nuxt`，通过 `persist: true` 开启持久化。

### `src/middleware/` — 路由中间件

```ts
// middleware/auth.ts
export default defineNuxtRouteMiddleware((to) => {
  const token = useCookie('token');
  if (!token.value) {
    return navigateTo(`/login?redirect=${encodeURIComponent(to.fullPath)}`);
  }
});
```

页面中启用：

```vue
<script setup lang="ts">
definePageMeta({ middleware: 'auth' });
</script>
```

### `src/plugins/` — Nuxt 插件

全局插件，应用启动时执行：

```ts
// plugins/element-plus.ts
export default defineNuxtPlugin((nuxtApp) => {
  // 全局注册、指令、错误处理等
});
```

命名后缀可控制运行端：`xxx.client.ts`（仅客户端）、`xxx.server.ts`（仅服务端）。

### `src/plugin/` — 可插拔业务插件

**注意与 `src/plugins/` 的区别**：

| 目录 | 含义 |
| --- | --- |
| `src/plugins/` | Nuxt 官方约定的全局插件目录 |
| `src/plugin/` | Madong 极速后台开发框架的**可插拔业务模块**目录 |

`nuxt.config.ts` 中自动收集：

```ts
/**
 * 收集各插件的 Nuxt 插件文件（可插拔）。
 * 约定：`src/plugin/{name}/plugins/*.ts` 会被自动纳入 Nuxt 插件。
 * 插件移除后目录不存在即自动跳过，核心功能不受影响。
 */
function collectPluginPlugins(): string[] {
  const cwd = process.cwd();
  const pluginRoot = path.resolve(cwd, 'src', 'plugin');
  if (!fs.existsSync(pluginRoot)) return [];
  const result: string[] = [];
  for (const name of fs.readdirSync(pluginRoot)) {
    const pluginsDir = path.join(pluginRoot, name, 'plugins');
    if (!fs.existsSync(pluginsDir)) continue;
    for (const file of fs.readdirSync(pluginsDir)) {
      if (file.endsWith('.ts')) {
        result.push(path.relative(cwd, path.join(pluginsDir, file)));
      }
    }
  }
  return result;
}
```

详见 [3.2.6 前端插件](plugin.md)。

### `src/assets/` — 样式与资源

```
assets/
├── css/
│   └── uno-reset.css
└── scss/
    ├── index.scss
    └── element/index.scss    Element Plus 主题变量
```

全局样式在 `nuxt.config.ts` 注册：

```ts
css: [
  '~/assets/css/uno-reset.css',
  '~/assets/scss/index.scss',
],
```

Element Plus 主题变量自动注入每个 SCSS 文件：

```ts
vite: {
  css: {
    preprocessorOptions: {
      scss: {
        additionalData: `@use "@/assets/scss/element/index.scss" as element;`,
      },
    },
  },
},
```

## 四、路径别名

| 别名 | 指向 |
| --- | --- |
| `~/` | `src/` |
| `@/` | `src/` |

```ts
import { request } from '~/api/request';
import type { Article } from '~/types/content';
```

> 与 admin 端的 `#/` 不同，web 端用 Nuxt 默认的 `~/`。

## 五、已启用的 Nuxt 模块

```ts
modules: [
  '@nuxt/eslint',
  '@vueuse/nuxt',
  '@unocss/nuxt',
  '@pinia/nuxt',
  '@element-plus/nuxt',
  'nuxt-icons',
  'pinia-plugin-persistedstate/nuxt',
],
```

| 模块 | 作用 |
| --- | --- |
| `@nuxt/eslint` | 代码规范 |
| `@vueuse/nuxt` | VueUse 自动导入（`ssrHandlers: true`） |
| `@unocss/nuxt` | 原子化 CSS |
| `@pinia/nuxt` | 状态管理 |
| `@element-plus/nuxt` | UI 组件（`importStyle: 'scss'`，`themes: ['dark']`） |
| `nuxt-icons` | 图标 |
| `pinia-plugin-persistedstate/nuxt` | 状态持久化 |

## 六、实验特性

```ts
experimental: {
  payloadExtraction: false,
  renderJsonPayloads: true,
  typedPages: true,
},
```

- `typedPages: true` — **路由类型安全**，`navigateTo()` 会有路径自动补全
- `payloadExtraction: false` — 规避 generate 模式下 SW 预缓存的已知问题

## 七、代码放置速查

| 我要写… | 放在哪 |
| --- | --- |
| 新页面 | `src/pages/` |
| 菜单声明 | `src/pages/routes.ts` |
| 接口 | `src/api/<模块>/` |
| 复用组件 | `src/components/` |
| 组合式函数 | `src/composables/` |
| 全局状态 | `src/stores/` |
| 路由守卫 | `src/middleware/` |
| 全局插件 | `src/plugins/` |
| 可插拔功能模块 | `src/plugin/<name>/` |
| 全局样式 | `src/assets/scss/` |
| 类型 | `src/types/` |

> 下一节：[3.2.3 页面与路由](pages.md)
