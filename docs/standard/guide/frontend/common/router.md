# 路由与菜单

---

## 一、目录结构

```
src/router/
├── index.ts              路由实例创建
├── guard.ts              导航守卫
├── access.ts             权限路由生成
├── routes/
│   ├── index.ts              路由汇总
│   ├── core.ts               核心静态路由（登录、404 等）
│   ├── backend.ts            后端模式路由
│   └── modules/              路由模块
└── plugin/
    ├── index.ts
    └── scanner.ts        ⭐ 插件路由扫描器
```

---

## 二、路由分类

Madong 极速后台开发框架的路由分三类：

| 类型 | 来源 | 特点 |
| --- | --- | --- |
| **核心静态路由** | `routes/core.ts` | 硬编码，无需权限（登录页、404、403） |
| **后端菜单路由** | 后端接口返回 | 动态生成，`component` 为**字符串路径** |
| **插件路由** | `src/plugin/**/routes.ts` | 自动扫描，可为前端路由或后端菜单路由 |

### 2.1 前端路由 vs 后端菜单路由

判定依据是 `component` 字段类型：

| `component` 类型 | 归类 | 示例 |
| --- | --- | --- |
| 函数（`() => import(...)`） | **前端路由** | 直接注册到 Vue Router |
| 字符串（`'system/user/index'`） | **后端菜单路由** | 需经路径解析后动态加载 |
| `'BasicLayout'` / `'RouteView'` | **布局分组路由** | 作为容器，归入后端路由 |
| 无 `component` 但有 `children` | **分组路由** | 归入后端路由 |

---

## 三、插件路由扫描器

`src/router/plugin/scanner.ts` 中的 `PluginRouteScanner` 是插件化的核心。

### 3.1 能力清单

| 能力 | 说明 |
| --- | --- |
| 自动发现 | `import.meta.glob` 扫描 `src/plugin/**/routes{.ts,/index.ts}` |
| 自动模块识别 | 从路径提取插件名，注入 `meta.module` |
| 前后端分类 | 按 `component` 类型自动分流 |
| 错误隔离 | 单插件异常不影响其他插件 |
| 路径校验 | 开发环境校验组件 `.vue` 是否存在 |
| 菜单合并 | 深度合并进后端菜单树并排序 |
| 结果缓存 | 单例 + 缓存，避免重复扫描 |

### 3.2 扫描过程

```ts
scan(): { backendRoutes: any[]; frontendRoutes: RouteRecordRaw[] } {
  if (this.hasScanned) {
    return { frontendRoutes: this.cachedFrontendRoutes, backendRoutes: this.cachedBackendRoutes };
  }

  // 扫描所有插件路由文件
  const pluginRouteModules = import.meta.glob(
    '../../plugin/**/routes{.ts,/index.ts}',
    { eager: true },
  );

  // 扫描 routes/backend.ts 中的后端模式路由
  const backendModeRouteModules = import.meta.glob('../routes/backend.ts', { eager: true });

  Object.entries(pluginRouteModules).forEach(([filePath, module]) => {
    try {
      // 从路径提取插件名：'../../plugin/demo/routes.ts' → 'demo'
      const pluginName = filePath.replace('../../plugin/', '').split('/')[0];
      // ... 解析并处理
    } catch (error) {
      // 错误隔离：单个插件错误不影响全局
      console.error(`[PluginScanner] ❌ 插件路由扫描失败，文件路径：${filePath}`, error);
    }
  });
  // ...
}
```

### 3.3 支持的导出形式

三种写法都能被识别：

```ts
// 形式一：默认导出数组
export default [ { path: '/demo', ... } ];

// 形式二：具名导出 routes
export const routes = [ { path: '/demo', ... } ];

// 形式三：模块本身是数组（较少用）
```

解析逻辑：

```ts
const mod = module as { default?: any[]; routes?: any[] };
if (Array.isArray(mod)) {
  routes = mod;
} else if (Array.isArray(mod.default)) {
  routes = mod.default;
} else if (Array.isArray(mod.routes)) {
  routes = mod.routes;
}
```

### 3.4 自动注入 `meta.module`

```ts
// 合并父级 meta
const meta = { ...parentMeta, ...route.meta };
// 自动注入模块名：如果没有手动配置，默认使用当前插件名
if (!meta.module) {
  meta.module = pluginName;
}
```

`meta` 会**从父路由向子路由继承**，子路由可覆盖。

### 3.5 组件路径校验（开发环境）

后端菜单路由的 `component` 是字符串，扫描器会校验对应 `.vue` 是否存在：

```ts
private validateComponentPath(component, module, routePath, pluginName): void {
  let fullPath = component;

  if (module && !component.startsWith('plugin/') && !component.startsWith('views/')) {
    const moduleComponent = component.replace(/^\//, '');
    if (moduleComponent.endsWith('.vue')) {
      fullPath = `../../plugin/${module}/views/${moduleComponent}`;
    } else if (moduleComponent.includes('/')) {
      fullPath = `../../plugin/${module}/views/${moduleComponent}.vue`;
    } else {
      fullPath = `../../plugin/${module}/views/${moduleComponent}/index.vue`;
    }
  } else if (!component.endsWith('.vue')) {
    fullPath = `../../${component}.vue`;
  }

  if (!this.pageMap[fullPath]) {
    console.warn(
      `[PluginScanner] ⚠️  插件 ${pluginName} 的路由 ${routePath} 组件路径不存在`,
      `\n配置的路径: ${component}`,
      `\n解析后的路径: ${fullPath}`,
      `\n请检查文件是否存在`,
    );
  }
}
```

**路径补全规则**（插件 `demo` 为例）：

| 配置的 `component` | 解析为 |
| --- | --- |
| `'index'` | `plugin/demo/views/index/index.vue` |
| `'user/list'` | `plugin/demo/views/user/list.vue` |
| `'user/list.vue'` | `plugin/demo/views/user/list.vue` |
| `'plugin/demo/views/x'` | `plugin/demo/views/x.vue` |
| `'views/system/user/index'` | `views/system/user/index.vue` |

### 3.6 菜单合并

```ts
mergeBackendMenus(backendMenus: any[], forceRescan = false): any[] {
  const { backendRoutes } = this.scan();
  if (backendRoutes.length === 0) return backendMenus;

  const merged = [...backendMenus];
  const pluginRouteMap = new Map(backendRoutes.map((r) => [r.name, r]));

  // 深度合并路由树（相同 name 时插件路由优先）
  const mergeRouteTree = (routes: any[]): any[] => { /* ... */ };

  // 添加未在后端菜单中定义的插件路由
  backendRoutes.forEach((pluginRoute) => {
    const exists = this.findRouteByName(merged, pluginRoute.name);
    if (!exists) {
      // 插件路由默认 sort=9999，排在最后
      if (pluginRoute.sort === undefined) {
        pluginRoute.sort = 9999;
      }
      merged.push(pluginRoute);
    }
  });

  // 按 sort 升序排序
  return mergeRouteTree(merged).toSorted((a, b) => (a.sort ?? 0) - (b.sort ?? 0));
}
```

**合并规则**：

| 场景 | 行为 |
| --- | --- |
| 插件路由 `name` 与后端菜单相同 | 合并，**插件路由字段优先**（`{ ...route, ...pluginRoute }`） |
| 插件路由 `name` 不存在于后端菜单 | 追加到菜单末尾，默认 `sort = 9999` |
| 双方都有 `children` | 递归深度合并 |
| 排序 | 按 `sort` 升序，未设置视为 `0` |

### 3.7 API

```ts
import { pluginRouteScanner } from '#/router/plugin';

// 获取前端路由
const routes = pluginRouteScanner.getFrontendRoutes();

// 强制重新扫描
const routes2 = pluginRouteScanner.getFrontendRoutes(true);

// 合并到后端菜单
const menus = pluginRouteScanner.mergeBackendMenus(backendMenus);

// 查看扫描状态
const status = pluginRouteScanner.getStatus();
// { hasScanned: true, frontendCount: 3, backendCount: 5 }

// 清除缓存
pluginRouteScanner.clearCache();
```

### 3.8 开发环境日志

扫描时控制台会输出：

```
[PluginScanner] ✅ 插件 demo 扫描完成：前端路由 2 个，后端路由 3 个
[PluginScanner] ℹ️ 插件 xxx 未定义路由
[PluginScanner] ⚠️  插件 demo 的路由 /demo/user 组件路径不存在
[PluginScanner] ❌ 插件路由扫描失败，文件路径：../../plugin/xxx/routes.ts
```

---

## 四、编写插件路由

### 4.1 前端路由（`component` 为函数）

`src/plugin/demo/routes.ts`

```ts
import type { RouteRecordRaw } from 'vue-router';

const routes: RouteRecordRaw[] = [
  {
    path: '/demo',
    name: 'Demo',
    component: () => import('./views/index.vue'),
    meta: {
      title: 'Demo 插件',
      icon: 'ant-design:appstore-outlined',
      order: 100,
    },
  },
];

export default routes;
```

### 4.2 后端菜单路由（`component` 为字符串）

```ts
export default [
  {
    path: '/codegen',
    name: 'Codegen',
    component: 'BasicLayout',          // 布局容器
    meta: { title: '代码生成', icon: 'ant-design:code-outlined' },
    sort: 500,
    children: [
      {
        path: 'table',
        name: 'CodegenTable',
        component: 'table',            // → plugin/codegen/views/table/index.vue
        meta: { title: '数据表管理' },
      },
    ],
  },
];
```

### 4.3 `meta` 常用字段

| 字段 | 说明 |
| --- | --- |
| `title` | 菜单标题（支持 i18n key） |
| `icon` | 图标（Iconify 名称） |
| `order` / `sort` | 排序 |
| `module` | 所属模块（不填自动注入插件名） |
| `hideInMenu` | 是否在菜单中隐藏 |
| `keepAlive` | 是否缓存页面 |
| `authority` | 所需权限 |
| `affixTab` | 是否固定标签页 |

---

## 五、导航守卫

`src/router/guard.ts` 负责：

```
路由跳转
    ↓
① 进度条开始（nprogress）
    ↓
② 是否需要登录？
   ├─ 否 → 放行
   └─ 是 → 检查 token
             ├─ 无 token → 跳转登录页（带 redirect）
             └─ 有 token → 是否已加载动态路由？
                            ├─ 否 → 拉取用户信息 + 菜单 → 生成路由 → 重新导航
                            └─ 是 → 权限校验
                                     ├─ 有权限 → 放行
                                     └─ 无权限 → 403
    ↓
③ 设置页面标题
    ↓
④ 进度条结束
```

---

## 六、动态路由生成

`src/router/access.ts` 负责将后端菜单转换为 Vue Router 可用的路由：

```
后端返回菜单树（component 为字符串）
        ↓
pluginRouteScanner.mergeBackendMenus() 合并插件路由
        ↓
遍历菜单树，将 component 字符串解析为组件加载函数
        ↓
component: 'system/user/index'
        → () => import('#/views/system/user/index.vue')
        ↓
router.addRoute() 动态注册
```

**组件路径解析规则**与扫描器的 `validateComponentPath` 保持一致。

---

## 七、路由缓存与标签页

| 特性 | 实现 | 说明 |
| --- | --- | --- |
| 页面缓存 | `meta.keepAlive` | 配合 `<KeepAlive>` |
| 标签页 | `core/ui/tabs/` | 多标签页管理 |
| 固定标签 | `meta.affixTab` | 不可关闭的标签 |

---

## 八、常见问题

**Q：插件路由没生效**
A：
1. 确认文件路径符合 `src/plugin/<name>/routes.ts` 或 `src/plugin/<name>/routes/index.ts`。
2. 确认正确导出（`export default []` 或 `export const routes = []`）。
3. 查看控制台是否有 `[PluginScanner]` 相关日志。
4. 尝试 `pluginRouteScanner.getFrontendRoutes(true)` 强制重扫。

**Q：控制台提示"组件路径不存在"**
A：按 [路径补全规则](#35-组件路径校验开发环境) 核对 `component` 字符串与实际文件位置。

**Q：插件菜单排序不对**
A：设置路由的 `sort` 字段；未设置时插件路由默认为 `9999`（排最后）。

**Q：插件路由与后端菜单冲突**
A：`name` 相同时会合并且**插件路由字段优先**。若想以后端为准，请修改插件路由的 `name`。

**Q：修改了插件路由但页面不更新**
A：扫描结果有缓存，需重启开发服务或调用 `clearCache()`。

---

## 九、下一步

- [权限控制](./access.md)
- [插件 → 前端插件开发](../../plugin/frontend-plugin.md)
