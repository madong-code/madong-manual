# 通用规范总览

> ⭐ **本章为所有 UI 分册共享的通用知识，与具体 UI 库无关，请务必先读完本章再看分册。**

---

## 一、本章覆盖内容

| 章节 | 说明 | 重要度 |
| --- | --- | --- |
| [工程结构约定](./project-structure.md) | 目录职责、命名规则、代码放置决策 | ★★★★★ |
| [UI 适配层设计](./ui-adapter.md) | 多套 UI 的核心机制 | ★★★★★ |
| [请求层与 API 约定](./request.md) | axios 封装、`BaseService`、错误处理 | ★★★★★ |
| [路由与菜单](./router.md) | 静态/动态路由、插件路由扫描 | ★★★★☆ |
| [权限控制](./access.md) | 路由级、按钮级、数据级权限 | ★★★★☆ |
| [状态管理](./store.md) | Pinia、持久化、加密存储 | ★★★☆☆ |
| [国际化](./i18n.md) | 语言包组织与按需加载 | ★★★☆☆ |
| [主题与样式](./theme.md) | Tailwind、CSS 变量、暗黑模式 | ★★★☆☆ |
| [环境变量与构建](./build.md) | 多环境配置、Vite、产物优化 | ★★★☆☆ |
| [新增一套 UI 指南](./add-new-ui.md) | 接入新 UI 的完整清单 | ★★★★☆ |

---

## 二、通用层与 UI 层边界

理解这条边界是掌握 MDAdmin 前端的关键。

### 2.1 完全通用（换 UI 零改动）

```
src/
├── api/          ✅ 接口定义
├── views/        ✅ 业务视图（只写抽象组件名）
├── store/        ✅ 状态管理
├── router/       ✅ 路由
├── locales/      ✅ 国际化逻辑
├── lang/         ✅ 语言包
├── enums/        ✅ 枚举
├── types/        ✅ 类型
├── utils/        ✅ 工具
├── plugin/       ✅ 前端插件
└── core/
    ├── request/      ✅ 请求层
    ├── access/       ✅ 权限
    ├── stores/       ✅ 内核状态
    ├── composables/  ✅ 组合式函数
    ├── shared/       ✅ 共享工具
    └── locales/      ✅ 国际化内核
```

### 2.2 UI 强相关（换 UI 必改）

```
src/
├── adapter/                       ❌ 全量重写
│   ├── component/index.ts             组件映射与类型
│   ├── form.ts                        表单适配
│   ├── crud/index.ts                  CRUD 适配
│   └── vxe-table.ts                   表格适配
│
├── components/form/components/    ⚠️ 内部实现重写
│   ├── api-dict/  api-select/  input/ …
│
└── core/
    ├── ui/         ⚠️ UI 基座部分调整
    ├── design/     ⚠️ 设计变量
    └── layouts/    ⚠️ 布局样式
```

---

## 三、贯穿全局的核心约定

### 3.1 路径别名

```ts
'#'    → src/
'#lib' → lib/
```

**统一使用 `#/`，不使用 `@/`。**

### 3.2 文件命名

| 类型 | 规则 | 示例 |
| --- | --- | --- |
| 目录 | kebab-case | `api-select-dept/` |
| Vue 组件文件 | kebab-case | `user-tag.vue` |
| 组件目录入口 | `index.vue` | `api-dict/index.vue` |
| TS 模块 | kebab-case | `component-map.ts` |
| Schema | `schemas/index.tsx` | 固定 |
| 类型定义 | `types.ts` | 固定 |

### 3.3 目录结构范式

**页面**：

```
views/<业务域>/<模块>/
├── index.vue              页面入口
├── schemas/index.tsx      CRUD 配置
└── components/            页面专属组件
```

**接口**：

```
api/<业务域>/<模块>/
├── index.ts               接口方法
└── types.ts               类型定义
```

业务域保持前后端一致：`system` / `member` / `content` / `ops` / `web` / `app` / `devtools`。

### 3.4 抽象组件类型

业务 Schema 中 `component` 字段填**抽象类型名**，不直接写 UI 库组件：

```ts
// ✅ 正确
{ component: 'Input',     fieldName: 'name' }
{ component: 'ApiDict',   fieldName: 'enabled' }
{ component: 'Textarea',  fieldName: 'description' }

// ❌ 错误：绑死了 UI 库
{ component: 'ElInput',   fieldName: 'name' }
```

可用类型见 `src/adapter/component/index.ts` 的 `ComponentType`：

```
ApiDict · ApiSelect · ApiSelectDept · ApiSelectPosition · ApiSelectRole
ApiTreeSelect · Avatar · Checkbox · CheckboxGroup · DatePicker · Divider
Editor · IconPicker · Input · InputNumber · KeyValueEditor · Password
RadioGroup · Select · Space · Switch · Textarea · TimePicker · TreeSelect · Upload
```

### 3.5 查询前缀

```ts
'LINK_name'    → name LIKE '%value%'
'EQ_enabled'   → enabled = value
```

### 3.6 权限标识

统一格式 `<域>:<模块>:<动作>`：

```
system:admin:read    system:admin:create
system:admin:update  system:admin:delete
member:tag:assign_permissions
```

前端三处需一致：Schema 的 `permissions`、按钮的 `auth`、后端菜单配置的权限标识。

### 3.7 大整数 ID

后端 Model 将 `id` 转为 string（`$casts = ['id' => 'string']`），前端类型也应声明为 `string`：

```ts
export interface GoodsCategory {
  id: string;    // ✅ 不要用 number
  // ...
}
```

项目引入 `json-bigint` 处理大整数精度问题。

---

## 四、通用开发流程

```
① 确定业务域与模块名（与后端一致）
        ↓
② api/<域>/<模块>/types.ts    定义类型
        ↓
③ api/<域>/<模块>/index.ts    基于 BaseService 定义接口
        ↓
④ views/<域>/<模块>/schemas/index.tsx    配置 CRUD Schema
        ↓
⑤ views/<域>/<模块>/index.vue            组装页面
        ↓
⑥ lang/zh-CN/<域>.json + lang/en-US/<域>.json    国际化
        ↓
⑦ 后台配置菜单与权限
```

---

## 五、常见误区

| ❌ 误区 | ✅ 正确做法 |
| --- | --- |
| 在 `views/` 里 `import { ElInput } from 'element-plus'` | 用抽象类型 `component: 'Input'` |
| 用 `@/` 别名 | 用 `#/` |
| 直接 `axios.get()` | 用 `requestClient` 或 `BaseService` |
| 硬编码中文 | 用 `$t('...')` |
| `id` 用 `number` 类型 | 用 `string` |
| 手动注册表单组件 | 放入 `components/form/components/` 自动扫描 |
| 修改 `frontend/packages/*` | 只改 `apps/*` 业务代码 |
| 页面里写大量业务逻辑 | 抽到 `schemas/` 与 `composables/` |

---

## 六、下一步

按顺序阅读：

1. [工程结构约定](./project-structure.md)
2. [UI 适配层设计](./ui-adapter.md) ← **多套 UI 核心**
3. [请求层与 API 约定](./request.md)
4. [路由与菜单](./router.md)
5. [权限控制](./access.md)
