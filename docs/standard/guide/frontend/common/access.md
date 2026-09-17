# 权限控制

---

## 一、权限层级

MDAdmin 前端权限分三层：

| 层级 | 控制粒度 | 实现 |
| --- | --- | --- |
| **路由级** | 页面能否访问 | 动态路由生成 + 导航守卫 |
| **组件级** | 按钮/元素是否显示 | `v-access` 指令、`AccessControl` 组件、Schema 的 `auth` |
| **数据级** | 能看到哪些数据 | 后端查询作用域（前端无感知） |

---

## 二、目录结构

```
src/core/access/
├── index.ts                导出
├── use-access.ts           ⭐ 权限判断组合式函数
├── directive.ts            v-access 指令
├── access-control.vue      AccessControl 组件
├── accessible.ts           路由可访问性处理
└── use-access.test.ts      单元测试
```

---

## 三、权限模式

`preferences.app.accessMode` 有两种取值：

| 模式 | 说明 |
| --- | --- |
| `frontend` | 前端模式，路由在前端定义，按角色控制 |
| `backend` | 后端模式，路由由后端菜单动态生成，按权限码控制 |

```ts
const { accessMode, toggleAccessMode } = useAccess();

// 切换模式
await toggleAccessMode();
```

> MDAdmin 后台默认使用 **`backend` 模式**（菜单由后端下发）。

---

## 四、`useAccess` 核心 API

`src/core/access/use-access.ts`：

```ts
function useAccess() {
  const accessStore = useAccessStore();
  const userStore = useUserStore();
  const accessMode = computed(() => preferences.app.accessMode);

  /** 基于角色判断是否有权限 */
  function hasAccessByRoles(roles: string[]) {
    const userRoleSet = new Set(userStore.userRoles);
    const intersection = roles.filter((item) => userRoleSet.has(item));
    return intersection.length > 0;
  }

  /** 基于权限码判断是否有权限 */
  function hasAccessByCodes(codes: string[]) {
    const userCodes = accessStore.accessCodes;
    const superCodes = accessStore.superCodes;
    const userCodesSet = new Set(userCodes);

    const intersection = codes.filter((item) => userCodesSet.has(item));
    const superMatched = userCodes.some((code) => superCodes.includes(code));

    return superMatched || intersection.length > 0;
  }

  return { accessMode, hasAccessByCodes, hasAccessByRoles, toggleAccessMode };
}
```

### 4.1 判断逻辑

| 方法 | 逻辑 |
| --- | --- |
| `hasAccessByRoles(roles)` | 用户角色与传入角色**有交集**即通过 |
| `hasAccessByCodes(codes)` | 命中**超级权限码** 或 与用户权限码**有交集**即通过 |

### 4.2 超级权限码

```ts
superCodes: ['*']    // 默认值
```

若用户的 `accessCodes` 中包含 `*`，则**拥有所有权限**，任何 `hasAccessByCodes` 判断都返回 `true`。

```ts
accessStore.setSuperCodes(['*', 'admin']);   // 可自定义超级码
```

---

## 五、组件级权限

### 5.1 `v-access` 指令

```vue
<!-- 按权限码 -->
<el-button v-access:code="'system:admin:create'">新增</el-button>
<el-button v-access:code="['system:admin:create', 'system:admin:import']">
  新增或导入
</el-button>

<!-- 按角色（仅 frontend 模式生效） -->
<el-button v-access:role="'admin'">管理员操作</el-button>
<el-button v-access:role="['admin', 'super']">操作</el-button>
```

**实现**（`directive.ts`）：

```ts
function isAccessible(el, binding) {
  const { accessMode, hasAccessByCodes, hasAccessByRoles } = useAccess();
  const value = binding.value;
  if (!value) return;

  const authMethod =
    accessMode.value === 'frontend' && binding.arg === 'role'
      ? hasAccessByRoles
      : hasAccessByCodes;

  const values = Array.isArray(value) ? value : [value];
  if (!authMethod(values)) {
    el?.remove();       // ⚠️ 直接移除 DOM
  }
}

const authDirective: Directive = { mounted };
```

**注意事项**：

| 特性 | 说明 |
| --- | --- |
| 生效时机 | 仅 `mounted` 钩子，**权限变化不会重新计算** |
| 处理方式 | `el.remove()` 直接移除 DOM，不可恢复 |
| 模式影响 | `v-access:role` 只在 `frontend` 模式下走角色判断，`backend` 模式下一律走权限码 |
| 空值 | `value` 为空时直接放行（不移除） |

> ⚠️ 若权限可能动态变化（如切换租户），请改用 `AccessControl` 组件。

### 5.2 `AccessControl` 组件

```vue
<script setup lang="ts">
import { AccessControl } from '#/core/access';
</script>

<template>
  <!-- 按权限码 -->
  <AccessControl type="code" :codes="['system:admin:create']">
    <el-button>新增</el-button>
  </AccessControl>

  <!-- 按角色（默认 type='role'） -->
  <AccessControl :codes="['admin']">
    <el-button>管理员操作</el-button>
  </AccessControl>
</template>
```

**Props**：

| Prop | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `codes` | `string[]` | `[]` | 权限码或角色列表 |
| `type` | `'code' \| 'role'` | `'role'` | 判断方式 |

**与指令的区别**：

| | `v-access` | `AccessControl` |
| --- | --- | --- |
| 响应式 | ❌ 仅挂载时判断 | ✅ `computed` 响应式 |
| DOM 处理 | 移除元素 | 条件渲染 slot |
| 未传值 | 放行 | 放行（`v-if="!codes"`） |
| 使用成本 | 低（一个属性） | 略高（包一层） |

> **建议**：静态权限用指令，动态权限用组件。

### 5.3 Schema 中的权限

CRUD Schema 提供声明式权限配置：

```ts
export const useCrudSchema = (): CrudSchema => ({
  // CRUD 操作权限
  permissions: {
    add: 'goods:category:create',
    edit: 'goods:category:update',
    remove: 'goods:category:delete',
    view: 'goods:category:read',
  },

  // 自定义按钮权限
  tableActions: [
    {
      label: '分配权限',
      auth: 'system:role:assign_permissions',   // ⭐ auth 字段
      onClick: (_e, row) => { /* ... */ },
    },
  ],

  dropDownActions: [
    {
      label: '编辑',
      auth: 'goods:category:update',
      onClick: (_e, row) => { /* ... */ },
    },
  ],
});
```

无权限时按钮自动隐藏。

---

## 六、权限状态存储

`src/core/stores/modules/access.ts`：

```ts
interface AccessState {
  accessCodes: string[];        // 权限码
  accessMenus: MenuRecordRaw[]; // 可访问菜单
  accessRoutes: RouteRecordRaw[]; // 可访问路由
  accessToken: AccessToken;     // 访问令牌
  isAccessChecked: boolean;     // 是否已检查过权限
  isLockScreen: boolean;        // 锁屏状态
  lockScreenPassword?: string;  // 锁屏密码
  loginExpired: boolean;        // 登录是否过期
  refreshToken: AccessToken;    // 刷新令牌
  superCodes: string[];         // 超级权限码，默认 ['*']
}
```

### 6.1 常用 Actions

```ts
const accessStore = useAccessStore();

accessStore.setAccessToken(token);       // 设置访问令牌
accessStore.setRefreshToken(token);      // 设置刷新令牌
accessStore.setAccessCodes(codes);       // 设置权限码
accessStore.setSuperCodes(['*']);        // 设置超级权限码
accessStore.setAccessMenus(menus);       // 设置菜单
accessStore.setAccessRoutes(routes);     // 设置路由
accessStore.setIsAccessChecked(true);    // 标记已检查
accessStore.setLoginExpired(true);       // 标记登录过期
accessStore.getMenuByPath('/system/user'); // 按路径查菜单（递归）
accessStore.lockScreen('password');      // 锁屏
accessStore.unlockScreen();              // 解锁
```

### 6.2 持久化

```ts
persist: {
  pick: [
    'accessToken',
    'refreshToken',
    'accessCodes',
    'isLockScreen',
    'lockScreenPassword',
  ],
}
```

只持久化以上五项，`accessMenus` / `accessRoutes` 每次登录重新拉取，避免菜单变更后缓存陈旧。

---

## 七、权限标识规范

统一格式：`<业务域>:<模块>:<动作>`

```
system:admin:read             查询
system:admin:create           新增
system:admin:update           编辑
system:admin:delete           删除
system:admin:export           导出
system:admin:import           导入
system:role:assign_permissions   分配权限
member:tag:batch_assign          批量打标签
```

**动作命名约定**：

| 动作 | 含义 |
| --- | --- |
| `read` / `list` | 查看 |
| `create` | 新增 |
| `update` | 编辑 |
| `delete` | 删除 |
| `export` | 导出 |
| `import` | 导入 |
| `change_status` | 改状态 |
| 其他 | 用蛇形命名描述具体动作 |

**三处必须一致**：

```
① 后端菜单管理中配置的权限标识
② 前端 Schema 的 permissions / auth
③ 后端接口的权限校验（Casbin 策略）
```

---

## 八、完整权限链路

```
① 用户登录
        ↓
② 后端返回 access_token + refresh_token
        ↓
③ accessStore.setAccessToken()
        ↓
④ 请求用户信息接口 → userStore（含 roles）
        ↓
⑤ 请求菜单/权限接口 → accessCodes + accessMenus
        ↓
⑥ pluginRouteScanner.mergeBackendMenus() 合并插件路由
        ↓
⑦ 菜单树 → 动态路由 → router.addRoute()
        ↓
⑧ accessStore.setIsAccessChecked(true)
        ↓
⑨ 页面渲染
   ├── 路由守卫拦截无权限页面
   ├── v-access / AccessControl 控制元素显隐
   └── Schema permissions / auth 控制 CRUD 按钮
        ↓
⑩ 接口请求携带 Token
        ↓
⑪ 后端 Casbin 二次校验（前端权限仅为体验优化，不可信）
```

> 🔒 **安全铁律**：前端权限控制**只是 UI 体验优化**，真正的安全边界在后端。任何接口都必须在后端做权限校验。

---

## 九、常见问题

**Q：按钮权限不生效，一直显示**
A：
1. 检查权限标识是否与后端菜单配置**完全一致**（大小写、冒号）。
2. 检查用户是否拥有超级权限码 `*`（超管默认全部通过）。
3. 打印 `accessStore.accessCodes` 确认权限码已下发。

**Q：`v-access:role` 不生效**
A：`accessMode` 为 `backend` 时，`role` 参数会被忽略，一律走权限码判断。改用 `v-access:code` 或切换模式。

**Q：切换租户后按钮权限没更新**
A：`v-access` 指令只在 `mounted` 时判断。改用 `AccessControl` 组件，或在切换后强制刷新页面/重载路由。

**Q：菜单显示了但点进去 403**
A：菜单权限与接口权限不一致。检查后端 Casbin 策略是否包含该接口。

**Q：刷新页面后菜单丢失**
A：`accessMenus` 不做持久化，需在路由守卫中检测 `isAccessChecked` 并重新拉取。

---

## 十、多套 UI 注意点

权限模块**完全与 UI 无关**：

| 文件 | 换 UI 时 |
| --- | --- |
| `use-access.ts` | ✅ 不改 |
| `directive.ts` | ✅ 不改 |
| `access-control.vue` | ✅ 不改（无 UI 组件依赖，只有 slot） |
| `accessible.ts` | ✅ 不改 |
| `stores/modules/access.ts` | ✅ 不改 |

唯一需要注意的是**示例代码中的按钮组件**（`<el-button>` → `<a-button>` → `<n-button>`），但那属于业务视图层。

---

## 十一、下一步

- [状态管理](./store.md)
- [路由与菜单](./router.md)
- [后端 → 权限体系 RBAC](../../backend/modules/rbac.md)
