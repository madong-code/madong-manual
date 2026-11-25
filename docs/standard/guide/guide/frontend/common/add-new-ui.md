# 新增一套 UI 指南

本页给出为 Madong 极速后台开发框架的后台接入**一套新 UI 组件库**的完整流程、清单与工作量评估。

> 前置阅读：[UI 适配层设计](./ui-adapter.md)

---

## 一、方案选择

接入新 UI 有两种方式，按需选择：

| 方案 | 做法 | 适用 | 优点 | 缺点 |
| --- | --- | --- | --- | --- |
| **A. 独立应用** | 复制 `template/admin/` 为 `template/admin-antd/` | 需要长期并行维护多套 | 隔离彻底，互不影响 | 业务代码需同步 |
| **B. 分支切换** | 同一应用内切换 `adapter/` 实现 | 只需一套，临时换肤 | 无冗余 | 无法同时存在 |

**推荐方案 A**，配合业务代码的软链接或同步脚本，兼顾隔离与复用。

---

## 二、命名约定

新增 UI 时统一命名，避免混乱：

| 项 | Element Plus | Ant Design Vue | Naive UI |
| --- | --- | --- | --- |
| 应用目录 | `template/admin/` | `template/admin-antd/` | `template/admin-naive/` |
| 包名 | `vue-vben-admin-ele` | `vue-vben-admin-antd` | `vue-vben-admin-naive` |
| 命名空间 | `madong-admin-ele` | `madong-admin-antd` | `madong-admin-naive` |
| 开发端口 | `5777` | `5778` | `5779` |
| 文档分册 | `docs/frontend/admin-ele/` | `docs/frontend/admin-antd/` | `docs/frontend/admin-naive/` |

---

## 三、完整步骤（方案 A）

### Step 1：复制应用骨架

```bash
cd template
cp -r admin admin-antd            # Windows: xcopy /E /I admin admin-antd
cd admin-antd

# 清理
rm -rf node_modules dist .vite pnpm-lock.yaml
```

### Step 2：修改标识信息

**`package.json`**：

```json
{
  "name": "vue-vben-admin-antd",
  "version": "5.7.0"
}
```

**`.env`**：

```ini
VITE_APP_TITLE=Madong 极速后台开发框架
VITE_APP_NAMESPACE=madong-admin-antd     # ⭐ 必须区分
VITE_APP_STORE_SECURE_KEY=your-own-key
VITE_APP_ICON_OFFLINE=false
```

**`.env.development`**：

```ini
VITE_PORT=5778                           # ⭐ 避免端口冲突
VITE_BASE=/
VITE_GLOB_API_URL=/adminapi
# 其余保持一致
```

> ⚠️ **`VITE_APP_NAMESPACE` 必须唯一**。它是 localStorage、缓存、store 持久化的前缀，若与其他 UI 相同，同域名部署时数据会互相污染。

### Step 3：替换依赖

```bash
# 移除 Element Plus 相关
pnpm remove element-plus @element-plus/icons-vue unplugin-element-plus

# 安装 Ant Design Vue 相关
pnpm add ant-design-vue @ant-design/icons-vue
pnpm add -D unplugin-vue-components
```

**保持不变的依赖**（UI 无关层）：

```
vue · vue-router · pinia · vue-i18n
vxe-table · vxe-pc-ui           表格
@iconify/vue · @iconify/json    图标
reka-ui                          无样式基础组件
vee-validate · zod               表单校验
tailwindcss                      样式
axios · @vueuse/core · dayjs     工具
echarts · @tiptap/* · @wangeditor/editor
```

### Step 4：改造 `vite.config.ts`

移除 Element Plus 专属配置：

```ts
// ❌ 删除
import ElementPlus from 'unplugin-element-plus/vite';

const ELEMENT_PLUS_STYLE_DEPS = [ /* ... */ ]
  .map((c) => `element-plus/es/components/${c}/style/css`);

plugins: [ ElementPlus({ format: 'esm' }) ],
optimizeDeps: { include: ELEMENT_PLUS_STYLE_DEPS },
```

替换为 Ant Design Vue 的按需引入：

```ts
// ✅ 新增
import Components from 'unplugin-vue-components/vite';
import { AntDesignVueResolver } from 'unplugin-vue-components/resolvers';

plugins: [
  Components({
    resolvers: [AntDesignVueResolver({ importStyle: false })],
  }),
],
```

保留不变的部分：

```ts
resolve: {
  alias: {
    '#': fileURLToPath(new URL('src', import.meta.url)),
    '#lib': fileURLToPath(new URL('lib', import.meta.url)),
  },
},
server: {
  proxy: {
    '/adminapi': { /* 保持一致 */ },
    '/upload':   { /* 保持一致 */ },
  },
},
```

### Step 5：重写 `src/adapter/component/index.ts`

这是**核心工作**。保持 `ComponentType` 契约不变，只换实现：

```ts
import type { Component } from 'vue';
import type { Recordable } from '#/core/shared/types';
import type {
  ApiComponentSharedProps,
  BaseFormComponentType,
  IconPickerProps,
} from '#/core/ui/common';

// ① 类型来源换成新库
import type {
  CheckboxProps,
  DatePickerProps,
  InputNumberProps,
  InputProps,
  SelectProps,
  SwitchProps,
  UploadProps,
} from 'ant-design-vue';

import { defineAsyncComponent, defineComponent, h, ref } from 'vue';
import { notification } from 'ant-design-vue';

import { $t } from '#/core/locales';
import { globalShareState } from '#/core/ui/common';
import { getAll as getFormComponents } from '../../components/form/component-map';

// ② 异步加载新库组件
const AInput = defineAsyncComponent(() =>
  import('ant-design-vue/es/input').then((res) => res.default),
);
const AInputNumber = defineAsyncComponent(() =>
  import('ant-design-vue/es/input-number').then((res) => res.default),
);
const ADatePicker = defineAsyncComponent(() =>
  import('ant-design-vue/es/date-picker').then((res) => res.default),
);

// ③ 包装器逻辑可直接复用（无需改动）
const withDefaultPlaceholder = <T extends Component>(
  component: T,
  type: 'input' | 'select',
  componentProps: Recordable<any> = {},
) => {
  return defineComponent({
    name: component.name,
    inheritAttrs: false,
    setup: (props: any, { attrs, expose, slots }) => {
      const placeholder =
        props?.placeholder || attrs?.placeholder || $t(`ui.placeholder.${type}`);
      const innerRef = ref();
      expose(
        new Proxy({}, {
          get: (_t, key) => innerRef.value?.[key],
          has: (_t, key) => key in (innerRef.value || {}),
        }),
      );
      return () =>
        h(component, { ...componentProps, placeholder, ...props, ...attrs, ref: innerRef }, slots);
    },
  });
};

// ④ ⭐ ComponentType 保持完全一致（契约不变）
export type ComponentType =
  | 'ApiDict'
  | 'ApiSelect'
  | 'ApiSelectDept'
  | 'ApiSelectPosition'
  | 'ApiSelectRole'
  | 'ApiTreeSelect'
  | 'Avatar'
  | 'Checkbox'
  | 'CheckboxGroup'
  | 'DatePicker'
  | 'Divider'
  | 'Editor'
  | 'IconPicker'
  | 'Input'
  | 'InputNumber'
  | 'KeyValueEditor'
  | 'Password'
  | 'RadioGroup'
  | 'Select'
  | 'Space'
  | 'Switch'
  | 'Textarea'
  | 'TimePicker'
  | 'TreeSelect'
  | 'Upload'
  | BaseFormComponentType;

// ⑤ 属性类型映射换成新库类型
export interface ComponentPropsMap {
  ApiDict: Record<string, any>;
  ApiSelect: ApiComponentSharedProps & SelectProps;
  Checkbox: CheckboxProps;
  DatePicker: DatePickerProps;
  Input: InputProps;
  InputNumber: InputNumberProps;
  Select: SelectProps;
  Switch: SwitchProps;
  Textarea: InputProps;
  Upload: UploadProps;
  // ...
}

// ⑥ 注册
async function initComponentAdapter() {
  const formComponents = getFormComponents();
  const formComponentsObj: Partial<Record<ComponentType, Component>> = {};
  formComponents.forEach((comp, name) => {
    formComponentsObj[name as ComponentType] = comp;
  });

  const components: Partial<Record<ComponentType, Component>> = {
    ...formComponentsObj,
    Input: withDefaultPlaceholder(AInput, 'input'),
    InputNumber: withDefaultPlaceholder(AInputNumber, 'input'),
    Textarea: withDefaultPlaceholder(AInput.TextArea, 'input'),
    DatePicker: ADatePicker,
  };

  globalShareState.setComponents(components);

  // ⑦ 全局消息 API 适配
  globalShareState.defineMessage({
    copyPreferencesSuccess: (title, content) => {
      notification.success({
        message: title,
        description: content,
        placement: 'bottomRight',
        duration: 0,
      });
    },
  });
}

export { initComponentAdapter };
```

### Step 6：调整 `src/adapter/form.ts`

重新梳理各组件的 v-model 属性名：

```ts
setupVbenForm<ComponentType>({
  config: {
    modelPropNameMap: {
      Upload: 'fileList',          // Ant Design Vue 同样是 fileList
      CheckboxGroup: 'value',      // ⚠️ 与 Element Plus 的 'model-value' 不同
      Switch: 'checked',           // ⚠️ Ant Design Vue 特有
    },
  },
  defineRules: {
    // 校验规则与 UI 无关，直接复用
    required: (value, _params, ctx) => { /* ... */ },
    selectRequired: (value, _params, ctx) => { /* ... */ },
  },
});
```

> 这是最容易出错的地方，建议逐个组件实测。

### Step 7：重写业务表单组件

`src/components/form/components/` 下 20+ 个组件需逐个改造内部实现。

**铁律：对外契约不变**

```vue
<!-- api-dict/index.vue -->
<script setup lang="ts">
// ✅ props / emits / expose 必须与 Element Plus 版本完全一致
interface Props {
  code: string;
  renderType?: 'CheckboxGroup' | 'RadioGroup' | 'Select';
  isBtn?: boolean;
  clearable?: boolean;
}
const props = withDefaults(defineProps<Props>(), { /* ... */ });
const emit = defineEmits<{ 'update:modelValue': [value: any] }>();

// ⚠️ 只有这里换：内部用 ant-design-vue 组件替代 element-plus
</script>
```

**改造优先级**：

| 优先级 | 组件 | 理由 |
| --- | --- | --- |
| P0 | `input` `input-number` `select` `date-picker` `radio-group` `checkbox-group` | 基础，几乎每个页面都用 |
| P0 | `api-dict` | 字典组件，使用频率最高 |
| P1 | `api-select` `api-tree-select` `api-cascader` | 接口驱动组件 |
| P1 | `upload` `password` `avatar` | 常用 |
| P2 | `api-select-dept` `api-select-position` `api-select-role` | 含弹窗，改造量大 |
| P2 | `icon-picker` `image-picker` `image-selector` | 含弹窗 |
| P3 | `editor` `key-value-editor` `divider` | 使用较少或与 UI 无关 |

### Step 8：适配 CRUD 与表格

**`src/adapter/crud/index.ts`**：适配弹窗、确认框、消息提示 API。

**`src/adapter/vxe-table.ts`**：VXE Table 与 UI 无关，主要调整主题变量对齐与渲染器（如 `CellDictTag`）内部使用的标签组件。

### Step 9：调整 UI 基座与主题

| 目录 | 工作 |
| --- | --- |
| `src/core/ui/` | 布局、菜单、标签页、弹层的样式与组件替换 |
| `src/core/design/` | CSS 变量映射到新库的设计令牌 |
| `src/layouts/` | 布局样式微调 |

### Step 10：验证

```bash
pnpm install
pnpm dev
```

**验证清单**：

- [ ] 登录页正常，可登录
- [ ] 菜单树渲染正常，路由跳转正常
- [ ] 标签页开关、右键菜单正常
- [ ] 列表页：表格渲染、分页、排序
- [ ] 搜索表单：各类型控件可用，`LINK_`/`EQ_` 查询生效
- [ ] 新增/编辑弹窗：表单渲染、校验提示、提交
- [ ] 详情视图：`hideInDetail`、`viewComponent` 生效
- [ ] 删除确认框
- [ ] 按钮级权限（`auth`）显隐正确
- [ ] 字典组件 `ApiDict` 各 `renderType` 正常
- [ ] 部门/岗位/角色选择弹窗
- [ ] 文件上传
- [ ] 富文本编辑器
- [ ] 图标选择器
- [ ] 暗黑模式切换
- [ ] 主题色切换
- [ ] 中英文切换
- [ ] 插件页面（codegen、demo）
- [ ] 租户切换（如启用）

### Step 11：补充文档

填充 `docs/frontend/admin-antd/` 下九个章节，并更新：

- `docs/frontend/index.md` 分册状态表（🚧 → ✅）
- `docs/README.md` 多套 UI 说明表

---

## 四、工作量评估

| 阶段 | 内容 | 预估 |
| --- | --- | --- |
| 环境搭建 | 复制、改名、换依赖、改 Vite | 0.5 天 |
| 适配层重写 | `adapter/` 四个文件 | 2~3 天 |
| 业务组件改造 | 20+ 个组件 | 5~8 天 |
| UI 基座与主题 | `core/ui/`、`core/design/` | 3~5 天 |
| 联调验证 | 全量功能回归 | 2~3 天 |
| 文档补充 | 分册九章 | 1~2 天 |
| **合计** | | **约 14~22 人日** |

---

## 五、常见坑

| 坑 | 表现 | 解决 |
| --- | --- | --- |
| 命名空间未改 | 多套 UI 同域名部署时登录态互相覆盖 | 改 `VITE_APP_NAMESPACE` |
| `modelPropNameMap` 遗漏 | 某些控件双向绑定失效，值不回填 | 逐个组件核对 v-model 属性名 |
| 组件契约被改 | 业务页面报 props 类型错误 | 保持 props/emits 完全一致 |
| 样式冲突 | 两套 UI 样式互相污染 | 确保只引入一套 UI 的样式 |
| 图标体系混用 | 图标不显示 | 统一走 `@iconify/vue` |
| 业务代码残留 UI import | 换库后编译报错 | 全局搜索 `from 'element-plus'` 清理 |
| 端口冲突 | 启动失败 | 改 `VITE_PORT` |
| 表格主题不一致 | VXE Table 与新 UI 风格割裂 | 调整 `adapter/vxe-table.ts` 主题变量 |

**自查命令**：

```bash
# 业务层不应出现任何 UI 库 import
grep -rn "from 'element-plus'" src/views src/api src/store src/router
grep -rn "from 'ant-design-vue'" src/views src/api src/store src/router
```

以上命令应**无输出**，有输出即为设计破坏，需修正。

---

## 六、维护多套 UI 的建议

### 6.1 业务代码同步策略

```
方式一：Git Submodule / Subtree
   将 views/ api/ store/ 等通用层抽为独立仓库

方式二：软链接（开发期）
   admin-antd/src/views  →  admin/src/views

方式三：同步脚本
   scripts/sync-business.js 定期同步通用层

方式四：抽为 workspace 包
   packages/business/ 被各 UI 应用引用（最规范，改造量大）
```

### 6.2 CI 保障

对每套 UI 分别执行：

```bash
pnpm typecheck
pnpm lint
pnpm test:unit
pnpm build
```

### 6.3 契约变更流程

修改 `ComponentType` 属于**破坏性变更**，需：

1. 在所有 UI 分册中同步实现新组件。
2. 更新各分册的「组件适配」文档。
3. 全量回归测试。

---

## 七、下一步

- [UI 适配层设计](./ui-adapter.md)
- [Ant Design Vue 分册（预留）](../admin-antd/index.md)
- [Naive UI 分册（预留）](../admin-naive/index.md)
