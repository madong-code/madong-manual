# UI 适配层设计

> ⭐ 本页是 Madong 极速后台开发框架 **多套 UI 支持**的核心，理解它就理解了为什么可以换 UI 而业务代码不动。

---

## 一、设计目标

| 目标 | 说明 |
| --- | --- |
| 业务与 UI 解耦 | `views/` 不出现任何 UI 库的 import |
| 单点切换 | 换 UI 库时改动集中在 `src/adapter/` |
| 类型安全 | Schema 中 `component` 与 `componentProps` 有联动类型提示 |
| 可扩展 | 新增业务组件自动注册，无需改适配层 |

---

## 二、整体结构

```
src/adapter/
├── component/
│   └── index.ts        ⭐ 组件映射 + 抽象类型声明 + 全局消息
├── form.ts             表单引擎适配（setupVbenForm）
├── crud/
│   └── index.ts        CRUD 适配（useCrud）
└── vxe-table.ts        表格适配（VXE Table 配置）
```

配合两个关键协作方：

```
src/components/form/component-map.ts     业务表单组件自动扫描注册
src/core/ui/common (globalShareState)    全局组件共享状态
```

---

## 三、组件适配：`adapter/component/index.ts`

### 3.1 三段式结构

```
① 组件导入与包装      异步加载 UI 库组件 + withDefaultPlaceholder 包装
        ↓
② 抽象类型声明        ComponentType（可用组件名）+ ComponentPropsMap（属性类型）
        ↓
③ 注册到全局          initComponentAdapter() → globalShareState.setComponents()
```

### 3.2 组件异步加载

为减小首屏体积，UI 组件按需异步加载，并同步加载其样式：

```ts
const ElDatePicker = defineAsyncComponent(() =>
  Promise.all([
    import('element-plus/es/components/date-picker/index'),
    import('element-plus/es/components/date-picker/style/css'),
  ]).then(([res]) => res.ElDatePicker),
);

const ElInput = defineAsyncComponent(() =>
  Promise.all([
    import('element-plus/es/components/input/index'),
    import('element-plus/es/components/input/style/css'),
  ]).then(([res]) => res.ElInput),
);

const ElInputNumber = defineAsyncComponent(() =>
  Promise.all([
    import('element-plus/es/components/input-number/index'),
    import('element-plus/es/components/input-number/style/css'),
  ]).then(([res]) => res.ElInputNumber),
);
```

### 3.3 `withDefaultPlaceholder` 包装器

不同 UI 库对 placeholder 的默认行为不一致，通过包装器统一补齐，同时**透传组件实例方法**：

```ts
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
        props?.placeholder ||
        attrs?.placeholder ||
        $t(`ui.placeholder.${type}`);

      // 透传组件暴露的方法（如 focus / blur）
      const innerRef = ref();
      expose(
        new Proxy({}, {
          get: (_target, key) => innerRef.value?.[key],
          has: (_target, key) => key in (innerRef.value || {}),
        }),
      );

      return () =>
        h(
          component,
          { ...componentProps, placeholder, ...props, ...attrs, ref: innerRef },
          slots,
        );
    },
  });
};
```

**属性优先级**（后覆盖前）：`componentProps` < `placeholder` < `props` < `attrs`。

### 3.4 抽象类型声明

```ts
// 这里需要自行根据业务组件库进行适配，需要用到的组件都需要在这里类型说明
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
```

**这是业务代码与 UI 库之间的契约**：无论底层换成哪套 UI，这份类型清单应保持稳定。

### 3.5 属性类型映射

```ts
/**
 * 与 ComponentType 中注册的组件名一一对应，
 * 便于 Schema 上 `component` + `componentProps` 联动提示
 */
export interface ComponentPropsMap {
  ApiDict: Record<string, any>;
  ApiSelect: ApiComponentSharedProps & SelectV2Props;
  ApiTreeSelect: ApiComponentSharedProps & ElTreeSelectSchemaProps;
  Checkbox: CheckboxProps;
  CheckboxGroup: CheckboxGroupProps;
  DatePicker: DatePickerProps;
  Input: InputProps;
  InputNumber: InputNumberProps;
  RadioGroup: RadioGroupProps;
  Select: SelectV2Props;
  Switch: SwitchProps;
  Textarea: InputProps;
  TimePicker: ElTimePickerSchemaProps;
  TreeSelect: ElTreeSelectSchemaProps;
  Upload: UploadProps;
  // ...
}
```

作用：在 Schema 中写 `component: 'Input'` 时，`componentProps` 会自动获得 `InputProps` 的类型提示。

> 📌 换 UI 库时，这些类型来源（`element-plus` 的 `InputProps` 等）需替换为新库的对应类型。

### 3.6 注册到全局

```ts
async function initComponentAdapter() {
  // ① 从 component-map 获取所有业务表单组件（自动扫描的）
  const formComponents = getFormComponents();
  const formComponentsObj: Partial<Record<ComponentType, Component>> = {};
  formComponents.forEach((comp, name) => {
    formComponentsObj[name as ComponentType] = comp;
  });

  // ② 合并：业务组件 + UI 库直接映射的组件
  const components: Partial<Record<ComponentType, Component>> = {
    ...formComponentsObj,

    Input: withDefaultPlaceholder(ElInput, 'input'),
    InputNumber: withDefaultPlaceholder(ElInputNumber, 'input'),
    Textarea: withDefaultPlaceholder(ElInput, 'input', { type: 'textarea' }),

    DatePicker: (props, { attrs, slots }) => {
      const { name, id, type } = props;
      const extraProps: Recordable<any> = {};
      // range 类型需要拆分 name/id 为数组
      if (type && type.includes('range')) {
        if (name && !Array.isArray(name)) {
          extraProps.name = [name, `${name}_end`];
        }
        if (id && !Array.isArray(id)) {
          extraProps.id = [id, `${id}_end`];
        }
      }
      return h(ElDatePicker, { ...props, ...attrs, ...extraProps }, slots);
    },
  };

  // ③ 注册到全局共享状态
  globalShareState.setComponents(components);

  // ④ 定义全局消息提示（不同 UI 库 API 不同，需适配）
  globalShareState.defineMessage({
    copyPreferencesSuccess: (title, content) => {
      ElNotification({
        title,
        message: content,
        position: 'bottom-right',
        duration: 0,
        type: 'success',
      });
    },
  });
}

export { initComponentAdapter };
```

**关键点**：`globalShareState.setComponents()` 把映射表注入全局，表单引擎渲染时按 `component` 名从中取组件。

### 3.7 优先级规则

```
components/form/components/ 自动扫描的业务组件（先展开）
                ↓ 被覆盖
adapter/component/index.ts 中显式声明的映射（后覆盖）
```

即：若 `components/form/components/input/index.vue` 存在且适配层又显式声明了 `Input`，**以适配层为准**。

---

## 四、业务组件自动注册：`components/form/component-map.ts`

### 4.1 自动扫描机制

```ts
const componentMap = new Map<string, Component>();

/** kebab-case → PascalCase：input-number => InputNumber */
function toPascalCase(str: string): string {
  return str
    .split('-')
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1).toLowerCase())
    .join('');
}

// 扫描所有子目录中的 index.vue
const modules = import.meta.glob('./components/**/index.vue', { eager: true });
for (const [path, mod] of Object.entries(modules)) {
  const match = path.match(/\/components\/([^/]+)\/index\.vue$/);
  if (match?.[1]) {
    add(toPascalCase(match[1]), markRaw(mod.default));
  }
}

// 扫描根目录下的 *.vue
const flatModules = import.meta.glob('./components/*.vue', { eager: true });
for (const [path, mod] of Object.entries(flatModules)) {
  const match = path.match(/\/components\/([^/]+)\.vue$/);
  if (match?.[1]) {
    add(toPascalCase(match[1]), markRaw(mod.default));
  }
}

// 开发环境打印扫描结果，便于排查
import.meta.env.DEV &&
  console.warn('[component-map] 扫描到的组件:', [...componentMap.keys()]);
```

### 4.2 命名映射表

| 文件路径 | 注册名 |
| --- | --- |
| `components/api-dict/index.vue` | `ApiDict` |
| `components/api-select/index.vue` | `ApiSelect` |
| `components/api-select-dept/index.vue` | `ApiSelectDept` |
| `components/api-tree-select/index.vue` | `ApiTreeSelect` |
| `components/input-number/index.vue` | `InputNumber` |
| `components/icon-picker/index.vue` | `IconPicker` |
| `components/key-value-editor/index.vue` | `KeyValueEditor` |
| `components/radio-group/index.vue` | `RadioGroup` |

### 4.3 现有业务组件清单

```
components/form/components/
├── api-cascader/          级联选择
├── api-checkbox-group/    接口多选组
├── api-component/         通用接口组件基座
├── api-dict/              字典组件 ⭐ 最常用
├── api-radio-group/       接口单选组
├── api-select/            接口下拉
├── api-select-dept/       部门选择（含 dept-select-dialog.vue）
├── api-select-position/   岗位选择（含 position-select-dialog.vue）
├── api-select-role/       角色选择（含 role-select-dialog.vue）
├── api-tree-select/       树形下拉
├── avatar/                头像
├── checkbox-group/        多选组
├── date-picker/           日期选择
├── divider/               分割线
├── editor/                富文本编辑器
├── icon-picker/           图标选择
├── image-picker/          图片选择（含 image-picker-dialog.vue）
├── image-selector/        图片选择器
├── input/                 输入框
├── input-number/          数字输入
├── key-value-editor/      键值对编辑
├── password/              密码输入
├── radio-group/           单选组
├── select/                下拉选择
└── upload/                上传
```

### 4.4 新增业务组件

只需三步：

```
① 创建 src/components/form/components/my-picker/index.vue
② 在 adapter/component/index.ts 的 ComponentType 中加入 'MyPicker'
③ （可选）在 ComponentPropsMap 中声明属性类型
```

无需手动注册，重启开发服务即可在 Schema 中使用：

```ts
{ component: 'MyPicker', fieldName: 'xxx' }
```

### 4.5 API 一览

```ts
add(name, component)                 // 添加
del(name)                            // 删除
get(name)                            // 获取
has(name)                            // 判断存在
getAll()                             // 获取全部 Map
registerToGlobalState(components)    // 批量注册到全局
```

---

## 五、表单适配：`adapter/form.ts`

```ts
import { setupVbenForm, useVbenForm as useForm, z } from '#/core/ui/common';

async function initSetupVbenForm() {
  setupVbenForm<ComponentType>({
    config: {
      // 不同组件的 v-model 属性名差异，在此声明
      modelPropNameMap: {
        Upload: 'fileList',
        CheckboxGroup: 'model-value',
      },
    },
    defineRules: {
      required: (value, _params, ctx) => {
        if (value === undefined || value === null || value.length === 0) {
          return $t('ui.formRules.required', [ctx.label]);
        }
        return true;
      },
      selectRequired: (value, _params, ctx) => {
        if (value === undefined || value === null) {
          return $t('ui.formRules.selectRequired', [ctx.label]);
        }
        return true;
      },
    },
  });
}

const useVbenForm = useForm<ComponentType, ComponentPropsMap>;
```

### 5.1 `modelPropNameMap`

**换 UI 库时必须重新梳理**。不同 UI 库组件的双向绑定属性名不同：

| 组件 | Element Plus | 说明 |
| --- | --- | --- |
| `Upload` | `fileList` | 非标准 `modelValue` |
| `CheckboxGroup` | `model-value` | 连字符形式 |

### 5.2 扩展 Schema 类型

```ts
type BaseFormSchema = FormSchema<ComponentType, ComponentPropsMap>;

/**
 * 扩展 VbenFormSchema，增加 viewComponent 和 viewComponentProps
 * 用于 DetailView 详情展示
 */
export type VbenFormSchema = {
  /** 在详情模式下隐藏该字段 */
  hideInDetail?: boolean;
  /** 详情模式使用的展示组件名称 */
  viewComponent?: string;
  /** 详情模式展示组件的参数 */
  viewComponentProps?: Record<string, any>;
} & BaseFormSchema;
```

用法：

```ts
{
  fieldName: 'password',
  label: '密码',
  component: 'Password',
  hideInDetail: true,          // 详情页不展示密码
}
```

---

## 六、CRUD 与表格适配

| 文件 | 职责 |
| --- | --- |
| `adapter/crud/index.ts` | 导出 `useCrud`，绑定 CRUD 组件与 UI 库的弹窗、消息、确认框 |
| `adapter/vxe-table.ts` | VXE Table 全局配置、单元格渲染器（如 `CellDictTag`）、与 UI 库主题对齐 |

> VXE Table 本身与 UI 库无关，`vxe-table.ts` 主要做**主题变量对齐**与**渲染器注册**，换 UI 时改动量较小。

---

## 七、完整渲染链路

以 Schema 中 `{ component: 'ApiDict', fieldName: 'enabled' }` 为例：

```
① Schema 声明
   { component: 'ApiDict', componentProps: { code: 'SYS_ENABLED_STATUS' } }
            ↓
② 表单引擎读取 component 名称 'ApiDict'
            ↓
③ 从 globalShareState 取组件映射表
            ↓
④ 映射表来源：
   ├── component-map 自动扫描 → components/form/components/api-dict/index.vue
   └── adapter 显式声明（若有，优先）
            ↓
⑤ 渲染 api-dict/index.vue
            ↓
⑥ 该组件内部使用 Element Plus 的 ElSelect 等具体组件
            ↓
⑦ 输出 DOM
```

**换 UI 库时**：①②③④⑤ 的链路不变，只需重写 ⑥ 中各业务组件的内部实现。

---

## 八、初始化时机

适配层需在应用启动时初始化，通常在 `src/bootstrap.ts` 中：

```ts
import { initComponentAdapter } from '#/adapter/component';
import { initSetupVbenForm } from '#/adapter/form';

async function bootstrap() {
  await initComponentAdapter();
  await initSetupVbenForm();
  // ... 其他初始化
}
```

> 顺序要求：`initComponentAdapter()` 必须先于表单渲染执行，否则组件映射表为空。

---

## 九、换 UI 时的改动清单

| 文件 | 改动程度 | 说明 |
| --- | --- | --- |
| `adapter/component/index.ts` | 🔴 全量重写 | 组件导入、包装器、类型来源、全局消息 |
| `adapter/form.ts` | 🟡 中等 | `modelPropNameMap` 需按新库梳理 |
| `adapter/crud/index.ts` | 🟡 中等 | 弹窗、确认框、消息 API 适配 |
| `adapter/vxe-table.ts` | 🟢 轻微 | 主题变量对齐 |
| `components/form/components/*/index.vue` | 🔴 逐个重写 | 内部实现换库，**对外 props/emits 契约不变** |
| `core/ui/` | 🟡 部分调整 | 布局、菜单、标签页样式 |
| `core/design/` | 🟡 主题变量 | CSS 变量映射 |
| `vite.config.ts` | 🟡 插件替换 | 如 `unplugin-element-plus` → 新库按需插件 |
| `package.json` | 🟡 依赖替换 | UI 库依赖 |
| `.env` | 🟢 命名空间 | `VITE_APP_NAMESPACE` 需区分 |
| `views/` `api/` `store/` `router/` | ✅ 不动 | — |

详细步骤见 [新增一套 UI 指南](./add-new-ui.md)。

---

## 十、设计原则

1. **契约稳定**：`ComponentType` 是业务与 UI 之间的公共契约，非必要不增删。
2. **业务组件对外一致**：`components/form/components/` 下组件换库时可重写内部，但 `props`/`emits`/`expose` 必须保持不变。
3. **不在业务代码 import UI 库**：任何 `views/` 中出现 `from 'element-plus'` 都是设计破坏。
4. **差异下沉到适配层**：UI 库的 API 差异（属性名、事件名、插槽名）一律在 `adapter/` 内消化。
5. **异步加载优先**：体积较大的组件用 `defineAsyncComponent`。

---

## 十一、下一步

- [新增一套 UI 指南](./add-new-ui.md)
- [Element Plus 组件适配详解](../admin-ele/components.md)
- [表单与弹窗](../admin-ele/form.md)
