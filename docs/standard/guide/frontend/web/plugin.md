# 3.2.6 前端插件

web 端支持可插拔的业务插件：放进目录即生效，删除目录即卸载，核心功能不受影响。

> 当前 `src/plugin/` 为空（仅 `.gitkeep`），机制已就绪，可按本节约定开发。

## 一、两个 plugin 目录的区别

| 目录 | 归属 | 说明 |
| --- | --- | --- |
| `src/plugins/` | Nuxt 官方约定 | 全局插件，应用启动时执行 |
| `src/plugin/` | Madong 极速后台开发框架扩展 | **可插拔业务模块**，本节主题 |

注意是 `plugin`（无 s）和 `plugins`（有 s）。

## 二、加载机制

`nuxt.config.ts` 在配置评估阶段扫描插件目录：

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
        // 返回相对项目根的路径，与 Nuxt srcDir 解析保持一致
        result.push(path.relative(cwd, path.join(pluginsDir, file)));
      }
    }
  }
  return result;
}

export default defineNuxtConfig({
  srcDir: 'src',
  // 可插拔插件：合并各插件目录内的 Nuxt 插件
  plugins: collectPluginPlugins(),
  // ...
});
```

关键点：

- 只扫描 **`src/plugin/{name}/plugins/*.ts`**
- 目录不存在自动跳过，**不会报错**
- 扫描发生在**配置评估期**，因此**新增插件必须重启 dev server**

## 三、插件目录结构

```
src/plugin/<插件名>/
├── plugins/            Nuxt 插件（会被自动注册）★ 必需
│   └── index.ts
├── components/         插件组件
├── pages/              插件页面（需手动注册路由）
├── api/                插件接口
├── stores/             插件状态
├── composables/        插件组合式函数
└── lang/               插件语言包
```

只有 `plugins/*.ts` 是自动加载的，其他目录需要在插件入口中主动接入。

## 四、开发一个插件

以「在线客服」插件为例。

### 1. 目录

```
src/plugin/service/
├── plugins/
│   └── index.ts
├── components/
│   └── ServiceWidget.vue
├── api/
│   └── index.ts
└── stores/
    └── service.ts
```

### 2. 插件入口

`src/plugin/service/plugins/index.ts`

```ts
import { defineNuxtPlugin } from 'nuxt/app';

import ServiceWidget from '../components/ServiceWidget.vue';

export default defineNuxtPlugin((nuxtApp) => {
  // 全局注册组件
  nuxtApp.vueApp.component('ServiceWidget', ServiceWidget);

  // 提供全局方法
  return {
    provide: {
      openService: () => {
        // 打开客服面板
      },
    },
  };
});
```

使用：

```vue
<template>
  <ServiceWidget />
</template>

<script setup lang="ts">
const { $openService } = useNuxtApp();
</script>
```

### 3. 接口

`src/plugin/service/api/index.ts`

```ts
import request from '~/api/request';

export const ServiceApi = {
  sendMessage(content: string) {
    return request.post('/service/message', { content });
  },
  getHistory() {
    return request.get('/service/history');
  },
};
```

### 4. 状态

`src/plugin/service/stores/service.ts`

```ts
import { defineStore } from 'pinia';

import { ServiceApi } from '../api';

export const useServiceStore = defineStore('plugin-service', {
  state: () => ({
    messages: [] as any[],
    open: false,
  }),

  actions: {
    async loadHistory() {
      this.messages = await ServiceApi.getHistory();
    },
    toggle() {
      this.open = !this.open;
    },
  },
});
```

> 插件 store 的 id 建议加 `plugin-` 前缀，避免与主应用冲突。

### 5. 客户端专属逻辑

需要访问 `window` 等浏览器 API 时，文件名加 `.client` 后缀：

```
plugins/
├── index.ts           两端都执行
└── widget.client.ts   仅客户端执行
```

```ts
// plugins/widget.client.ts
export default defineNuxtPlugin(() => {
  window.addEventListener('resize', () => {
    // ...
  });
});
```

同理 `.server.ts` 仅服务端执行。

### 6. 插件页面

插件页面**不会**自动成为路由。两种接入方式：

**方式 A：在主 `pages/` 建一个薄壳页面**

```vue
<!-- src/pages/service/index.vue -->
<script setup lang="ts">
import ServicePage from '~/plugin/service/pages/index.vue';
</script>

<template>
  <ServicePage />
</template>
```

**方式 B：在插件中动态添加路由**

```ts
// plugins/index.ts
export default defineNuxtPlugin(() => {
  const router = useRouter();
  router.addRoute({
    path: '/service',
    name: 'plugin-service',
    component: () => import('../pages/index.vue'),
  });
});
```

然后按需在 `src/pages/routes.ts` 中补菜单声明。

## 五、卸载插件

删除 `src/plugin/<插件名>/` 目录，重启 dev server 即可。

`collectPluginPlugins()` 中的 `fs.existsSync` 判断保证目录不存在时静默跳过。

> 若插件使用了方式 A 的薄壳页面，记得一并删除对应的 `src/pages/` 文件。

## 六、与 admin 端插件的对比

| 维度 | admin 端 | web 端 |
| --- | --- | --- |
| 目录 | `src/plugin/<name>/` | `src/plugin/<name>/` |
| 扫描时机 | 构建期 `import.meta.glob` | 配置评估期 `fs.readdirSync` |
| 自动加载 | 路由 + 页面 + 语言包 | 仅 `plugins/*.ts` |
| 路由 | `routes/index.ts` 自动合并 | 需手动 `addRoute` 或建薄壳页面 |
| 语言包 | 自动扫描 `lang/` | 需手动接入 |

> admin 端插件机制更完整，web 端更轻量。

## 七、与后端插件配合

前端插件通常对应一个后端插件：

| 层 | 位置 |
| --- | --- |
| web 前端 | `template/web/src/plugin/<name>/` |
| admin 前端 | `template/admin/src/plugin/<name>/` |
| 后端 | `backend/plugin/<name>/` |

后端运行时只扫描 `backend/plugin/`，详见 [4.3.2 应用插件](../../backend/advanced/plugin.md)。

## 八、注意事项

1. **新增/删除插件必须重启 dev server** —— 扫描在配置评估期完成。
2. **只有 `plugins/*.ts` 自动加载** —— 其他资源需主动引入。
3. **store id 加前缀** —— 避免与主应用冲突。
4. **浏览器 API 用 `.client.ts`** —— 否则 SSR 下会报错。
5. **插件应自包含** —— 尽量不依赖其他插件。
6. **`.ts` 后缀才被扫描** —— `.js` 文件不会被收集。

> 下一章：[4. 后端开发](../../backend/index.md)
