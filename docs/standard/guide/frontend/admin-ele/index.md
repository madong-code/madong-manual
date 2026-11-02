# 后台管理 · Element Plus 分册总览

> 本分册是 **Element Plus（admin-ele）** 这一套后台管理 UI 的专属文档。
> 通用能力（适配层机制、请求、路由、权限、状态、i18n、主题、构建）请先阅读 [`../common/index.md`](../common/index.md)，本分册只描述 **Element Plus 专属的实现细节、组件清单与最佳实践**。

---

## 1. 这套 UI 是什么

- **UI 框架**：Element Plus（基于 Vue 3 的饿了么组件库）。
- **工程位置**：`template/admin/`（当前项目默认启用的后台管理前端）。
- **状态**：**已落地、文档完整**，本分册所有内容均为真实可用示例。
- **适配入口**：`src/adapter/component/index.ts`、`src/adapter/form.ts`、`src/adapter/crud/index.ts`。

> 其余两套（`admin-antd` / `admin-naive`）为**预留骨架**，目录与本节一致，但内容占位，详见 [`../admin-antd/index.md`](../admin-antd/index.md) 与 [`../admin-naive/index.md`](../admin-naive/index.md)。

---

## 2. 章节导航

| 章节 | 说明 |
| ---- | ---- |
| [快速上手](./getting-started.md) | 安装、启动、新增一个 CRUD 页面的最小路径 |
| [目录结构](./directory.md) | admin-ele 相关目录与文件职责 |
| [布局与骨架](./layout.md) | BasicLayout / AuthLayout / 菜单 / Tab / 面包屑 |
| [组件适配](./components.md) | Element Plus 组件如何接入 Vben 适配层（`component-map.ts` + `adapter/component`） |
| [表格与查询](./table.md) | `useCrud` + VxeTable 的列、搜索、操作、分页、树形 |
| [表单与弹窗](./form.md) | `FormDialog` 弹窗表单、字段组件、校验、详情、宽度布局（col-span/controlClass） |
| [主题定制](./theme.md) | Element Plus 主题变量、暗黑模式、CSS 变量 |
| [常见问题](./faq.md) | Element Plus 下的高频坑与排查 |

---

## 3. 与通用层的边界

```text
common（通用、UI 无关）           admin-ele（本分册，EP 专属）
─────────────────────────        ──────────────────────────────
adapter/ 机制设计                 adapter/component/index.ts 实际注册了哪些 EP 组件
ui-adapter.md 原理                adapter/form.ts 的校验规则、model 映射
request.md 拦截器                 无（复用）
router.md PluginRouteScanner      无（复用）
access.md useAccess               无（复用）
store.md Pinia                    无（复用）
i18n.md 三种 key 模式             lang/ 中的 EP 文案占位
theme.md 变量体系                 Element Plus --el-* 变量调参
build.md 环境变量                 无（复用）
add-new-ui.md 如何加新 UI         ——（本套即示例）
```

**原则**：凡是能通过 `adapter/` 抽象、与具体 UI 库无关的内容，一律写在 `common`，本分册只写「EP 在这里具体怎么接」。

---

## 4. 一句话上手

```bash
cd template/admin
pnpm install
pnpm dev        # 读取 .env，VITE_PORT 默认 5777，VITE_GLOB_API_URL=/adminapi
```

新增一个后台模块页面，只需 3 步：

1. `src/api/<module>/<entity>/index.ts` —— 继承 `BaseService` 生成 CRUD 接口；
2. `src/views/<module>/<entity>/schemas/index.tsx` —— 编写 `useCrudSchema()` 描述列、搜索、表单；
3. `src/views/<module>/<entity>/index.vue` —— `useCrud()` 渲染 `<BasicCrud />`。

详见 [快速上手](./getting-started.md)。
