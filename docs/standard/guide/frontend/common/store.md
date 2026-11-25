# 状态管理

Madong 极速后台开发框架使用 **Pinia** + `pinia-plugin-persistedstate` 管理状态。

---

## 一、结构

```
src/
├── core/stores/                 内核状态（框架层，勿改）
│   ├── index.ts
│   ├── setup.ts                 Pinia 初始化与持久化插件配置
│   └── modules/
│       ├── access.ts                权限与令牌
│       ├── user.ts                  用户信息
│       ├── tabbar.ts                标签页
│       └── timezone.ts              时区
│
└── store/                       业务状态（可自由添加）
    └── modules/
```

---

## 二、内核 Store

### 2.1 `useAccessStore` — 权限与令牌

```ts
import { useAccessStore } from '#/core/stores';

const accessStore = useAccessStore();
```

**State**：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `accessToken` | `null \| string` | 访问令牌 |
| `refreshToken` | `null \| string` | 刷新令牌 |
| `accessCodes` | `string[]` | 权限码 |
| `superCodes` | `string[]` | 超级权限码，默认 `['*']` |
| `accessMenus` | `MenuRecordRaw[]` | 可访问菜单 |
| `accessRoutes` | `RouteRecordRaw[]` | 可访问路由 |
| `isAccessChecked` | `boolean` | 是否已检查权限 |
| `loginExpired` | `boolean` | 登录是否过期 |
| `isLockScreen` | `boolean` | 锁屏状态 |
| `lockScreenPassword` | `string?` | 锁屏密码 |

**Actions**：

```ts
accessStore.setAccessToken(token);
accessStore.setRefreshToken(token);
accessStore.setAccessCodes(codes);
accessStore.setSuperCodes(['*']);
accessStore.setAccessMenus(menus);
accessStore.setAccessRoutes(routes);
accessStore.setIsAccessChecked(true);
accessStore.setLoginExpired(true);
accessStore.getMenuByPath('/system/user');   // 递归查找菜单
accessStore.lockScreen('password');
accessStore.unlockScreen();
```

**持久化字段**：

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

> `accessMenus` / `accessRoutes` **不持久化**，每次登录重新拉取，避免菜单变更后缓存陈旧。

### 2.2 `useUserStore` — 用户信息

```ts
import { useUserStore } from '#/core/stores';

const userStore = useUserStore();
userStore.userInfo;      // 用户信息
userStore.userRoles;     // 角色列表
```

### 2.3 `useTabbarStore` — 标签页

管理多标签页的打开、关闭、固定、刷新等。

### 2.4 `useTimezoneStore` — 时区

管理时区设置，影响时间显示格式化。

---

## 三、业务 Store

### 3.1 创建

`src/store/modules/goods.ts`

```ts
import { acceptHMRUpdate, defineStore } from 'pinia';

import { GoodsCategoryService } from '#/api/goods/category';

interface GoodsState {
  categories: any[];
  loading: boolean;
}

export const useGoodsStore = defineStore('goods', {
  state: (): GoodsState => ({
    categories: [],
    loading: false,
  }),

  getters: {
    enabledCategories: (state) =>
      state.categories.filter((item) => item.enabled === 1),
    categoryCount: (state) => state.categories.length,
  },

  actions: {
    async fetchCategories() {
      this.loading = true;
      try {
        this.categories = await GoodsCategoryService.getEnabledList();
      } finally {
        this.loading = false;
      }
    },
    reset() {
      this.categories = [];
    },
  },

  persist: {
    pick: ['categories'],     // 按需持久化
  },
});

// 解决热更新问题
const hot = import.meta.hot;
if (hot) {
  hot.accept(acceptHMRUpdate(useGoodsStore, hot));
}
```

### 3.2 使用

```vue
<script setup lang="ts">
import { storeToRefs } from 'pinia';
import { onMounted } from 'vue';

import { useGoodsStore } from '#/store/modules/goods';

const goodsStore = useGoodsStore();

// ⭐ 解构 state/getters 必须用 storeToRefs 保持响应式
const { categories, loading } = storeToRefs(goodsStore);

// actions 可直接解构
const { fetchCategories } = goodsStore;

onMounted(() => fetchCategories());
</script>
```

---

## 四、持久化

### 4.1 基本用法

```ts
persist: true                          // 持久化全部 state
persist: { pick: ['a', 'b'] }          // 只持久化指定字段
persist: { omit: ['loading'] }         // 排除指定字段
```

### 4.2 命名空间隔离

持久化 key 会带上 `VITE_APP_NAMESPACE` 前缀：

```ini
VITE_APP_NAMESPACE=madong-admin-ele
```

```
localStorage:
  madong-admin-ele-core-access
  madong-admin-ele-core-user
  madong-admin-ele-goods
```

> ⚠️ **多套 UI 必须使用不同的 `VITE_APP_NAMESPACE`**，否则同域名部署时数据互相覆盖。

### 4.3 加密存储

项目使用 `secure-ls` 对持久化数据加密，密钥来自：

```ini
VITE_APP_STORE_SECURE_KEY=please-replace-me-with-your-own-key
```

> 🔒 生产环境**必须替换**为自有密钥，且各环境/各 UI 分套建议使用不同密钥。

---

## 五、热更新支持

所有 Store 应在文件末尾添加 HMR 处理，否则开发时修改 Store 会导致状态错乱：

```ts
// 解决热更新问题
const hot = import.meta.hot;
if (hot) {
  hot.accept(acceptHMRUpdate(useGoodsStore, hot));
}
```

---

## 六、Store ID 命名

| 类型 | 前缀 | 示例 |
| --- | --- | --- |
| 内核 Store | `core-` | `core-access`、`core-user`、`core-tabbar` |
| 业务 Store | 无前缀 | `goods`、`order` |

```ts
defineStore('core-access', { /* ... */ });   // 内核
defineStore('goods', { /* ... */ });         // 业务
```

---

## 七、使用建议

| ✅ 推荐 | ❌ 避免 |
| --- | --- |
| 跨页面共享的状态放 Store | 页面内部状态也放 Store |
| 用 `storeToRefs` 解构 | 直接解构导致失去响应式 |
| 按需 `persist.pick` | 无脑 `persist: true` 持久化全部 |
| Store 中处理异步与缓存 | 在组件里散落请求逻辑 |
| 添加 HMR 处理 | 忘记导致开发体验差 |
| 敏感数据不持久化 | 明文存密码等敏感信息 |
| 业务 Store 放 `store/modules/` | 塞进 `core/stores/` |

---

## 八、什么时候该用 Store

| 场景 | 是否用 Store |
| --- | --- |
| 用户信息、权限、令牌 | ✅ 必须 |
| 多个页面共享的字典数据 | ✅ 推荐 |
| 跨组件通信（非父子） | ✅ 推荐 |
| 需要持久化的配置 | ✅ 推荐 |
| 单页面内的表单状态 | ❌ 用 `ref`/`reactive` |
| 父子组件传值 | ❌ 用 props/emits |
| 一次性的列表数据 | ❌ 用组件内状态 |

---

## 九、多套 UI 注意点

状态管理**完全与 UI 无关**，换 UI 时：

| 项 | 改动 |
| --- | --- |
| `core/stores/*` | ✅ 不改 |
| `store/modules/*` | ✅ 不改 |
| `VITE_APP_NAMESPACE` | ⚠️ **必须改**，避免数据污染 |
| `VITE_APP_STORE_SECURE_KEY` | ⚠️ 建议区分 |

---

## 十、下一步

- [国际化](./i18n.md)
- [权限控制](./access.md)
