# 3. 前端开发

Madong 极速后台开发框架的前端由两个独立应用组成，分别面向不同使用者：

| 应用 | 路径 | 面向 | 技术栈 | 对接后端 |
| --- | --- | --- | --- | --- |
| **admin** | `template/admin` | 管理员 | Vue 3 + Vite + TS + Element Plus（Vben 5.7 内核） | `app/adminapi` |
| **web** | `template/web` | 终端访客 | Nuxt 4 + Element Plus + UnoCSS | `app/api` |

此外还有 `template/install`（安装向导），仅在初始化阶段使用，见 [2.4 安装向导](../install/wizard.md)。

## 3.1 两端的差异

| 维度 | admin | web |
| --- | --- | --- |
| 渲染方式 | SPA（客户端渲染） | Nuxt（当前 `ssr: false`，可切换 SSR/SSG） |
| 路由 | 静态路由 + 后端下发的动态菜单 | 文件路由，支持 `frontend`/`backend` 两种模式 |
| 权限 | 基于角色/权限码的完整 RBAC | 以登录态为主，无复杂权限 |
| 核心场景 | 表格、表单、CRUD | 内容展示、SEO |
| 状态管理 | Pinia（持久化 + 加密） | Pinia（`@pinia/nuxt`） |

## 3.2 admin 端的核心思想

admin 端最重要的特点是**声明式 CRUD**：一个业务页面通常只需两个文件。

`views/system/post/index.vue` —— 页面本体只有 14 行：

```vue
<script setup lang="ts">
import { useCrud } from '#/adapter/crud';
import { Page } from '#/components/page';

import { useCrudSchema } from './schemas';

const [BasicCrud] = useCrud(useCrudSchema());
</script>

<template>
  <Page auto-content-height>
    <BasicCrud />
  </Page>
</template>
```

`views/system/post/schemas/index.tsx` —— 用一份配置描述接口、权限、列、搜索表单、编辑表单。

这种模式让"新增一个管理页面"的成本降到最低，详见 [3.1.8 CRUD 页面开发](admin/crud.md)。

## 3.3 阅读路线

### admin 端

1. [3.1.1 快速上手](admin/getting-started.md) — 跑起来
2. [3.1.2 目录结构](admin/directory.md) — 知道代码放哪
3. [3.1.3 请求层](admin/request.md) — 接口怎么调
4. [3.1.4 路由与菜单](admin/router.md) — 页面怎么出现在菜单里
5. [3.1.8 CRUD 页面开发](admin/crud.md) — **核心**，日常开发主要看这节
6. 其余按需查阅：[权限](admin/access.md)、[状态](admin/store.md)、[UI 适配](admin/ui-adapter.md)、[国际化](admin/i18n.md)、[插件](admin/plugin.md)、[构建](admin/build.md)

### web 端

[3.2.1 快速上手](web/getting-started.md) → [3.2.2 目录结构](web/directory.md) → [3.2.3 页面与路由](web/pages.md) → [3.2.4 请求与状态](web/request.md) → [3.2.5 渲染与 SEO](web/seo.md)

## 3.4 通用约定

### 路径别名

admin 端统一使用 `#/` 指向 `src/`：

```ts
import { requestClient } from '#/api/request';
import { $t } from '#/locales';
import { Page } from '#/components/page';
```

### 接口响应结构

后端统一返回：

```json
{ "code": 0, "msg": "ok", "data": {} }
```

请求层已自动解包，业务代码直接拿到 `data`，详见 [3.1.3 请求层](admin/request.md)。

### 查询参数前缀约定

搜索表单的字段名带操作符前缀，由后端 `madong/query` 解析：

| 前缀 | 含义 | 示例 |
| --- | --- | --- |
| `EQ_` | 等于 | `EQ_enabled` |
| `LIKE_` | 模糊匹配 | `LIKE_name` |
| `IN_` | 包含 | `IN_status` |
| `BETWEEN_` | 区间 | `BETWEEN_created_at` |

详见 [4.3.3 查询构造器](../backend/advanced/query.md)。

> 下一节：[3.1 admin 后台端](admin/index.md)
