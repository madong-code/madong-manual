# 3.1.8 CRUD 页面开发

这是 admin 端最核心的开发模式。**一份 `CrudSchema` 配置驱动表格、搜索、表单、权限与接口**，页面文件通常不足 20 行。

## 一、最小示例

`src/views/system/post/index.vue`

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

`useCrud()` 返回一个元组：

```ts
const [BasicCrud, crudApi] = useCrud(useCrudSchema());
```

- 第 1 项：组件，直接在模板里用
- 第 2 项：`CrudApiInstance`，用于命令式操作（刷新、开弹窗等）

## 二、CrudSchema 总览

```ts
interface CrudSchema extends Partial<TableConfig> {
  crudApi: CrudApi;                    // 必填：接口绑定
  columns?: CrudColumn[] | (() => CrudColumn[]);
  searchForm?: SearchFormConfig;       // 搜索区
  formDialog?: FormDialogConfig;       // 新增/编辑弹窗
  beforeFetch?: (params) => any;       // 请求前改参
  afterFetch?: (res) => any;           // 响应后改数据
  // ...以及 TableConfig 的全部字段（扁平化写在顶层）
}
```

> **扁平化设计**：`TableConfig` 的所有字段（`hasAdd`、`permissions`、`tree`、`toolbar`…）都直接写在顶层，不需要嵌套。

## 三、接口绑定 `crudApi`

```ts
interface CrudApi {
  list: (params: any) => Promise<any>;          // 必填
  add?: (params: any) => Promise<any>;
  edit?: (params: any) => Promise<any>;
  remove?: (params: any) => Promise<any>;       // 单个删除
  batchRemove?: (params: { ids: any[] }) => Promise<any>;  // 批量删除
  view?: (id: any) => Promise<any>;
}
```

配合 `BaseService` 使用：

```tsx
import { PostService } from '#/api/system/post';

crudApi: {
  list: PostService.list,
  add: PostService.create,
  edit: PostService.update,
  remove: PostService.delete,
  batchRemove: PostService.remove,
  view: PostService.get,
},
```

## 四、表格列 `columns`

```ts
interface CrudColumn {
  field?: string;
  title?: string;
  width?: number | string;
  minWidth?: number | string;
  type?: 'checkbox' | 'expand' | 'radio' | 'seq' | string;
  visible?: boolean;
  align?: 'center' | 'left' | 'right';
  auth?: string;                  // 列级权限
  cellRender?: { name: string; attrs?: Record<string, any> };
  viewComponent?: any;            // 详情态展示组件
  viewComponentProps?: Record<string, any>;
  vxeColumn?: Record<string, any>;
}
```

示例：

```tsx
columns: [
  { type: 'checkbox', width: 60 },
  { type: 'seq', title: '序号', width: 60 },
  { field: 'name', title: '岗位名称', minWidth: 160, align: 'left' },
  { field: 'code', title: '岗位编码', minWidth: 140 },
  {
    field: 'enabled',
    title: '状态',
    minWidth: 80,
    cellRender: {
      name: 'CellDictTag',
      attrs: { code: DictEnum.SYS_ENABLED_STATUS },
    },
  },
  { field: 'created_at', title: '创建时间', minWidth: 170 },
],
```

可用的 `cellRender.name` 见 [3.1.7 UI 适配层](ui-adapter.md#二单元格渲染器)：
`CellDict`、`CellDictTag`、`CellImage`、`CellLink`、`CellOperation`、`CellSwitch`、`CellTag`、`CellTags`。

> `columns` 支持传函数 `() => CrudColumn[]`，用于需要在运行时（如依赖国际化、字典）动态生成的场景。

## 五、搜索表单 `searchForm`

```ts
interface SearchFormConfig {
  enabled?: boolean;         // 默认 true
  schema?: VbenFormSchema[] | (() => VbenFormSchema[]);
  commonConfig?: Partial<VbenFormProps>;
  submitOnChange?: boolean;  // true=值变即查，false=按钮查（默认）
  collapsed?: boolean;       // 是否折叠，默认 false
  collapsedRows?: number;    // 折叠时显示行数，默认 2
}
```

```tsx
searchForm: {
  enabled: true,
  collapsed: true,
  collapsedRows: 2,
  schema: [
    {
      component: 'Input',
      fieldName: 'LIKE_name',
      label: '岗位名称',
      componentProps: { clearable: true, placeholder: '请输入岗位名称' },
    },
    {
      component: 'ApiDict',
      fieldName: 'EQ_enabled',
      label: '状态',
      componentProps: { clearable: true, code: DictEnum.SYS_ENABLED_STATUS },
    },
  ],
},
```

### 字段名前缀 = 查询操作符

这是 MDAdmin 的关键约定，**前端字段名直接声明查询语义，后端 `madong/query` 自动解析**，无需后端写任何 `if` 判断：

| 前缀 | 含义 | 示例字段名 |
| --- | --- | --- |
| `EQ_` | 等于 | `EQ_enabled` |
| `NEQ_` | 不等于 | `NEQ_status` |
| `LIKE_` | 模糊匹配 | `LIKE_name` |
| `GT_` / `GTE_` | 大于 / 大于等于 | `GT_price` |
| `LT_` / `LTE_` | 小于 / 小于等于 | `LTE_price` |
| `IN_` | 在集合内 | `IN_status` |
| `BETWEEN_` | 区间 | `BETWEEN_created_at` |

详见 [4.3.3 查询构造器](../../backend/advanced/query.md)。

## 六、表单弹窗 `formDialog`

```tsx
formDialog: {
  enabled: true,
  title: '岗位',
  dialogType: 'modal',          // 'modal' | 'drawer'
  width: 'w-[50%]',
  wrapperClass: 'grid-cols-1',  // 列数：grid-cols-1 / 2 / 3
  draggable: true,
  fullscreenButton: true,
  commonConfig: {
    labelWidth: 100,
    labelAlign: 'right',
  },
  schema: [
    {
      label: 'ID',
      fieldName: 'id',
      component: 'Input',
      dependencies: { triggerFields: ['id'], show: false },  // 隐藏但提交
    },
    {
      label: '岗位名称',
      fieldName: 'name',
      component: 'Input',
      rules: 'required',
    },
    {
      label: '状态',
      fieldName: 'enabled',
      component: 'ApiDict',
      defaultValue: 1,
      componentProps: {
        code: DictEnum.SYS_ENABLED_STATUS,
        isBtn: true,
        renderType: 'RadioGroup',
      },
    },
  ],
},
```

### 生命周期钩子

| 钩子 | 签名 | 用途 |
| --- | --- | --- |
| `onOpen` | `(type, data) => void` | 弹窗打开后，可动态改表单 |
| `transformFormValues` | `(values, type) => values` | 提交前数据转换 |
| `beforeSubmit` | `(values, type) => false \| values` | 提交前校验，返回 `false` 中断 |
| `onSuccess` | `(type, values) => void` | 提交成功后 |

`type` 为 `'add' | 'edit' | 'view'`。

```tsx
formDialog: {
  // 提交前：数组转字符串
  transformFormValues: (values) => ({
    ...values,
    tags: Array.isArray(values.tags) ? values.tags.join(',') : values.tags,
  }),

  // 提交前校验
  beforeSubmit: (values, type) => {
    if (type === 'add' && !values.code) {
      ElMessage.warning('岗位编码必填');
      return false;   // 中断提交
    }
    return values;
  },

  onSuccess: (type) => {
    ElMessage.success(type === 'add' ? '新增成功' : '修改成功');
  },
},
```

### 详情态复用

表单 schema 可通过三个扩展字段复用于详情展示：

```tsx
{
  label: '密码',
  fieldName: 'password',
  component: 'InputPassword',
  hideInDetail: true,          // 详情不展示
}
{
  label: '状态',
  fieldName: 'enabled',
  component: 'ApiDict',
  viewComponent: 'DictTag',    // 详情用标签展示
  viewComponentProps: { code: DictEnum.SYS_ENABLED_STATUS },
}
```

## 七、按钮与权限

```tsx
hasAdd: true,
hasEdit: true,
hasView: true,
hasRemove: true,
hasBatchRemove: true,

permissions: {
  add: 'org:post:create',
  edit: 'org:post:update',
  remove: 'org:post:delete',
  view: 'org:post:read',
},

buttonText: {
  add: '新建岗位',
  edit: '修改',
},
```

- `hasXxx` 控制**功能是否存在**
- `permissions.xxx` 控制**有权限才显示**

两者是"与"关系，详见 [3.1.5 权限控制](access.md)。

## 八、自定义操作按钮

```tsx
// 行内操作
tableActions: [
  {
    label: '重置密码',
    auth: 'system:admin:change_password',
    onClick: (row) => handleReset(row),
  },
],

// 行内下拉更多
dropDownActions: [
  {
    label: '分配角色',
    auth: 'system:admin:grant_role',
    onClick: (row) => openGrant(row),
    popConfirm: { title: '确认执行？' },
  },
],

// 工具栏按钮
toolbarActions: [
  { label: '导入', onClick: () => openImport() },
],

// 工具栏下拉
dropDownToolbarActions: [
  { label: '导出全部', onClick: () => exportAll() },
],

// 操作列本身的配置
tableActionColumn: { width: 200, title: '操作', fixed: 'right' },
```

## 九、树形表格

```tsx
tree: {
  id: 'id',
  pid: 'parent_id',
  children: 'children',
  reserve: true,     // 刷新后保持展开状态
},
pagerConfig: false,  // 树形通常不分页
```

## 十、分页与工具栏

```tsx
// 分页参数字段名（需与后端一致）
pagination: {
  currentKey: 'page',
  sizeKey: 'limit',
},

// 工具栏
toolbar: {
  refresh: true,
  custom: true,   // 列设置
  zoom: true,     // 全屏
  export: false,
  search: true,
  print: false,
},
```

> 响应字段（`items` / `total`）在 `adapter/vxe-table.ts` 中全局配置，不在这里。

## 十一、请求前后钩子

```tsx
// 请求前：注入固定参数、格式化日期区间
beforeFetch: (params) => {
  if (params.BETWEEN_created_at?.length === 2) {
    params.BETWEEN_created_at = params.BETWEEN_created_at.join(',');
  }
  return { ...params, EQ_type: 1 };
},

// 请求后：加工数据
afterFetch: (res) => {
  res.items = res.items.map((item) => ({
    ...item,
    fullName: `${item.first_name}${item.last_name}`,
  }));
  return res;
},
```

## 十二、路径参数 `pathParams`

用于详情子表这类需要携带父级 ID 的场景：

```tsx
pathParams: [
  { key: 'orderId', source: 'route', routeKey: 'id' },   // 取自路由参数
  { key: 'userId',  source: 'row',  field: 'user_id' },  // 取自行数据
],
```

## 十三、命令式 API

```vue
<script setup lang="ts">
import { useCrud } from '#/adapter/crud';

import { useCrudSchema } from './schemas';

const [BasicCrud, crudApi] = useCrud(useCrudSchema());

function refresh() {
  crudApi.query();            // 重新查询（回到第一页）
  crudApi.reload();           // 重载
  crudApi.refreshData();      // 刷新当前页
  crudApi.refreshSoft();      // 软刷新（不重置分页）
}

function openDialogs() {
  crudApi.openAddDialog({ dept_id: 1 });   // 带默认值新增
  crudApi.openEditDialog(row);
  crudApi.openViewDialog(row);
}

function selection() {
  const rows = crudApi.getRowSelection();  // 已选中行
}

function batchDelete() {
  crudApi.executeBatchRemove();
}
</script>
```

### 完整方法表

| 分类 | 方法 |
| --- | --- |
| 数据 | `query`、`reload`、`refreshData`、`refreshSoft`、`refreshCreate`、`refreshUpdate`、`refreshRemove` |
| 状态 | `setLoading`、`getReadonlyState`、`getRowSelection` |
| 实例 | `getGridInstance`、`getFormApi`、`setGridOptions` |
| 弹窗 | `openAddDialog`、`openEditDialog`、`openViewDialog` |
| 删除 | `removeByApi`、`executeRemove`、`executeBatchRemove` |

## 十四、完整参考示例

参考仓库内已有实现：

| 场景 | 路径 |
| --- | --- |
| 标准 CRUD | `src/views/system/post/` |
| 树形表格 | `src/views/system/dept/`、`src/views/system/menu/` |
| 含子组件的复杂页 | `src/views/system/role/`（授权菜单、数据范围、分配用户） |
| 多 Tab 配置页 | `src/views/system/config/` |
| 主从表 | `src/views/system/dict/` |

## 十五、开发清单

新增一个 CRUD 页面：

- [ ] `src/api/<域>/<模块>/types.ts` — 定义行类型
- [ ] `src/api/<域>/<模块>/index.ts` — `BaseService` 生成接口
- [ ] `src/views/<域>/<模块>/schemas/index.tsx` — CrudSchema
- [ ] `src/views/<域>/<模块>/index.vue` — 页面（模板化）
- [ ] 后台菜单管理配置菜单与权限码
- [ ] 角色管理分配权限

## 十六、常见问题

| 现象 | 原因 |
| --- | --- |
| 表格无数据但接口有返回 | 响应结构不是 `{ items, total }`，检查 `adapter/vxe-table.ts` 的 `proxyConfig.response` |
| 搜索条件不生效 | 字段名缺少 `LIKE_`/`EQ_` 前缀 |
| 编辑时 ID 丢失 | 表单 schema 缺少 `id` 隐藏字段 |
| 按钮不显示 | `hasXxx` 为 false，或权限码未分配 |
| 弹窗层级异常（嵌套时） | 设置 `formDialog.zIndex` 更高值 |
| 树形刷新后折叠 | 设置 `tree.reserve: true` |

> 下一节：[3.1.9 国际化](i18n.md)
