# Element Plus · 表单与弹窗

后台表单（新增/编辑/详情）统一由 `FormDialog` 弹窗承载，由 `CrudSchema.formDialog` 配置。

---

## 1. 表单渲染

`FormDialog` 内部使用 `useVbenForm`，表单字段来自 `formDialog.schema`：

```ts
formDialog: {
  schema: [
    { fieldName: 'name', label: $t('...'), component: 'Input', rules: 'required' },
    { fieldName: 'enabled', label: $t('...'), component: 'ApiDict',
      componentProps: { code: DictEnum.X, renderType: 'RadioGroup', isBtn: true },
      defaultValue: 1 },
  ],
  dialogType: 'modal',   // 'modal' | 'drawer'
  width: 'w-[40%]',
  title: $t('...'),
}
```

- `dialogType: 'drawer'` 可改为侧边抽屉。
- `width` 支持 Tailwind 宽度类，如 `w-[600px]` / `w-[90%]`。

---

## 2. 字段组件与 props

`component` 字符串对应 [`components.md`](./components.md) 注册的组件：

| component | 用途 |
| ---- | ---- |
| `Input` / `Textarea` | 文本 |
| `InputNumber` | 数字 |
| `DatePicker` | 日期（range 自动拆字段） |
| `ApiDict` | 字典下拉（绑定 `DictEnum`） |
| `ApiSelect` / `ApiTreeSelect` | 远程数据 |
| `Upload` | 文件/图片 |
| `Switch` / `RadioGroup` / `CheckboxGroup` | 状态/多选 |

`componentProps` 透传给底层组件（带 TS 类型提示，见 `ComponentPropsMap`）。

### ApiDict 渲染形态

```ts
componentProps: { code: DictEnum.SYS_ENABLED_STATUS, renderType: 'RadioGroup', isBtn: true }
```

- `renderType`：`Select` / `RadioGroup` / `CheckboxGroup`。
- `isBtn`：单选按钮组样式。

---

## 3. 校验

- 行内：`rules: 'required'` 或 `rules: 'selectRequired'`（预置规则）。
- 自定义函数：

```ts
rules: (value) => (value ? true : $t('ui.formRules.required'))
```

- 跨字段校验：在 `setupVbenForm` 中扩展 `defineRules`。

---

## 4. 详情（view）

`CrudSchema` 设置 `hasView: true` 时，列表操作列出现「详情」，弹窗以只读模式渲染 `formDialog.schema`，组件自动转 `disabled`。

---

## 5. 提交与回填

- **回填**：`FormDialog` 打开时调用 `crudApi.view(row.id)` 获取详情，按 `fieldName` 映射进表单 model。
- **提交**：新增调 `crudApi.add(model)`，编辑调 `crudApi.edit(model)`（自动带 `id`）。
- **Upload 注意**：`modelPropNameMap` 已配置 `Upload → fileList`，回填时后端返回 `fileList` 数组；提交前由组件转回后端所需结构。

---

## 6. 自定义表单布局

`schema` 支持 `group`（分组）与 `collapsed`：

```ts
schema: [
  { fieldName: 'name', component: 'Input', rules: 'required' },
  { fieldName: 'remark', component: 'Textarea' },
  { group: '高级', collapsed: true, schema: [ /* 折叠区字段 */ ] },
]
```

复杂联动（字段 A 变化影响字段 B 选项）用 `componentProps` 中的 `onChange` 或 `watch` 表单值。

---

## 7. 表单项与控件宽度布局

> 本节布局模型与 SaaS 参照模板 `madong-saas/template/mono` **完全一致**（曾短暂存在的 `formWidth` 配置已移除，不要在新代码中使用）。

弹窗表单的宽度由**三层开关**逐级控制，全部通过 `formDialog` 配置，不写内联 CSS：

| 层 | 配置 | 作用 | 默认值 |
| ---- | ---- | ---- | ---- |
| 弹窗 | `width` | 弹窗整体宽度 | `w-[50%]` |
| 网格 | `wrapperClass` | 表单列数（grid） | `grid-cols-1` |
| 字段 | `formItemClass` | 单个字段跨几列 | `col-span-1` |
| 控件 | `controlClass` | 字段内输入框/选择器的宽度 | 无（自适应 100%） |

**核心约定：表单内容层恒占满弹窗宽度**（modal 与 drawer 一致）。布局差异全部通过「字段占几列」和「控件多宽」表达。

### 常用配方

```ts
formDialog: {
  width: 'w-[60%]',
  // 配方一：一行一个 + 控件止于弹窗中部（member/user 采用）
  wrapperClass: 'grid-cols-2',
  commonConfig: { labelWidth: 100, controlClass: 'w-1/2!' },
  schema: [
    { fieldName: 'name', component: 'Input', formItemClass: 'col-span-2' },
    // 单字段覆盖全局（schema 级经 tailwind-merge 合并，同组后者胜）
    { fieldName: 'remark', component: 'Input', formItemClass: 'col-span-2',
      controlClass: 'w-full!',
      componentProps: { type: 'textarea', rows: 3 } },
  ],
}
```

```ts
formDialog: {
  // 配方二：一行两个（紧凑，mono/system-menu 风格）
  width: 'w-[60%]',
  dialogType: 'drawer',
  wrapperClass: 'grid-cols-2',
  commonConfig: { labelWidth: 80 },
  schema: [
    { fieldName: 'pid', component: 'ApiTreeSelect', formItemClass: 'col-span-1' },
    { fieldName: 'title', component: 'Input', formItemClass: 'col-span-1' },
    { fieldName: 'remark', component: 'Input', formItemClass: 'col-span-2' },
  ],
}
```

参考实现：`views/member/user/schemas/index.tsx`（配方一）、`views/system/menu/schemas/index.tsx`（配方二，drawer）。

### 控件宽度 `controlClass` 的覆盖规则

`commonConfig.controlClass` 全局生效，`schema[].controlClass` 单字段覆盖（`form.vue` 中 `cn(controlClass, schema.controlClass)` 经 tailwind-merge 合并，同组后者胜）。

### 排坑清单（每条都实际踩过）

1. **`controlClass: 'w-1/2'` 不生效**：Element Plus 的 `.el-input { width: 100% }` 与工具类同权重且加载在后。必须写 Tailwind 4 important 后缀 **`'w-1/2!'`**；同理单字段全宽用 `'w-full!'`。
2. **字段变成一行两个**：`wrapperClass: 'grid-cols-2'` 时字段必须是 `col-span-2` 才独占一行；`col-span-1` 是半行。两者混用是"忽宽忽窄"的常见原因（`system/menu` 等页面大量使用 `col-span-1`，复制 schema 时注意区分）。
3. **Tailwind 类不生成**：类名必须以字面量出现在源码文本中（如 `'w-1/2!'`），拼接字符串不会被扫描到。
4. **历史遗留**：`formWidth`（表单层半宽默认值）已从 `dialog.vue`/`crud.vue`/类型定义中整体移除并全站清理；若在旧分支见到该配置，升级时直接删除即可，布局改用 `controlClass` 表达。
