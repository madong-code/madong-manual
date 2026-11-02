# Element Plus · 常见问题

---

## Q1：表单字段回填为空 / 提交拿不到值

**原因**：`modelPropNameMap` 未为该组件配置 v-model 字段名（如 `Upload` 用 `fileList` 而非 `modelValue`）。
**排查**：检查 `adapter/form.ts` 的 `modelPropNameMap`；确认 Schema `fieldName` 与后端返回字段一致。

---

## Q2：新增表单组件后在 Schema 里 `component` 没提示 / 报错

**原因**：组件未被 `component-map` 扫描到，或未在 `ComponentType` 联合类型中声明。
**解决**：
1. 确认目录在 `src/components/form/components/<kebab>/index.vue`。
2. 组件已 `export default`，且在 `adapter/component/index.ts` 的 `components` 对象中注册（或来自自动扫描 map）。

---

## Q3：字典下拉（ApiDict）无数据

**原因**：`DictEnum.X` 对应的字典 `code` 后端未录入，或字典接口未授权。
**解决**：
- 确认后端「字典管理」中存在该 `code` 且已启用。
- 确认 `VITE_GLOB_API_URL` 正确，字典接口 `/adminapi/system/dict-data/...` 可访问。
- 开发控制台看请求是否 401（token 失效见 [`common/request.md`](../../common/request.md) 的自动刷新）。

---

## Q4：表格列 `cellRender.name` 不生效

**原因**：渲染器未在 `adapter/vxe-table.ts` 注册。
**解决**：确认使用了已注册渲染器（`CellDictTag` / `CellImage` / `CellLink` / `CellOperation`）；自定义渲染器需先在 vxe-table 注册。

---

## Q5：查询前缀 `LIKE_` / `EQ_` 后端不识别

**原因**：字段命名与后端约定不符，或前端提交时未保留前缀。
**解决**：前端 `searchForm.schema[].fieldName` 必须带前缀（如 `LIKE_name`）；后端解析见 [`backend/basic/request-response.md`](../../backend/basic/request-response.md)。前缀是字符串直接提交，请勿在提交拦截器里剥离。

---

## Q6：权限按钮没隐藏

**原因**：`permissions` 中的权限码与后端返回的 `codes` 不一致，或 `useAccess` 未初始化。
**解决**：
- 确认 `meta.authority` 与按钮 `code` 都使用后端实际下发的权限码。
- 确认登录后已拉取权限码并写入（见 [`common/access.md`](../../common/access.md)）。

---

## Q7：Element Plus 体积过大

**优化**：
- `adapter/component/index.ts` 中大组件已用 `defineAsyncComponent` 懒加载。
- 生产构建开启 `vite` 的 `manualChunks` 拆分 `element-plus`。
- 如不需要全量，可改为按需（项目已用 `unplugin-element-plus`，基本按需）。

---

## Q8：切换暗黑后 Element Plus 颜色没变

**原因**：覆盖了 `--el-color-primary` 但未在 `.dark` 下提供对应值，或引入顺序导致变量被覆盖。
**解决**：在 `src/styles` 中统一管理，确保 `:root` 与 `.dark` 都声明完整阶梯变量（见 [theme.md](./theme.md)）。

---

## Q9：弹窗表单控件宽度不生效 / 字段变成一行两个

**症状**：控件设置宽度没反应，或字段排布忽宽忽窄。

**原因与解决**（宽度由三层开关控制，逐层排查）：

1. `controlClass: 'w-1/2'` 挂上了类但没效果 → 被 Element Plus `.el-input { width: 100% }` 同权重覆盖，改用 Tailwind 4 important 后缀 `'w-1/2!'`。
2. 字段一行两个 → `wrapperClass: 'grid-cols-2'` 下字段是 `col-span-1`；独占一行需 `col-span-2`。从 `system/menu` 等页面复制 schema 时注意列配置不同。
3. 想让个别控件占满整行 → 字段级 `controlClass: 'w-full!'` 覆盖 `commonConfig` 全局限宽。
4. 历史配置 `formWidth` 已移除（对齐 mono：表单层恒占满弹窗），见 [form.md §7](./form.md)。
