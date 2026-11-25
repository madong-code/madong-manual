# 第一个功能

本页通过一个完整的「商品分类」CRUD 功能，带你走通 Madong 的**全栈开发流程**。

> 示例严格遵循项目现有约定，参考自真实模块 `member/tag`。

---

## 一、目标

实现商品分类管理：列表查询（分页 + 搜索）、新增、编辑、详情、删除，并接入权限控制。

**涉及文件**：

```
后端 backend/
├── app/model/goods/GoodsCategory.php              模型
├── app/dao/goods/GoodsCategoryDao.php             数据访问
├── app/service/admin/goods/GoodsCategoryService.php  业务服务
├── app/adminapi/validate/goods/GoodsCategoryValidate.php  校验器
└── app/adminapi/controller/goods/GoodsCategoryController.php  控制器

前端 template/admin/src/
├── api/goods/category/types.ts                    类型定义
├── api/goods/category/index.ts                    接口定义
├── views/goods/category/schemas/index.tsx         CRUD 配置
└── views/goods/category/index.vue                 页面
```

> 💡 **偷懒方案**：以上骨架可用[代码生成器](../dev-guide/codegen.md)一键生成。本页手写是为了讲清每层职责。

---

## 二、数据表

```sql
CREATE TABLE `md_goods_category` (
  `id`          bigint unsigned NOT NULL AUTO_INCREMENT,
  `name`        varchar(50)  NOT NULL DEFAULT '' COMMENT '分类名称',
  `parent_id`   bigint       NOT NULL DEFAULT 0  COMMENT '父级ID',
  `description` varchar(255) NOT NULL DEFAULT '' COMMENT '描述',
  `sort`        int          NOT NULL DEFAULT 0  COMMENT '排序',
  `enabled`     tinyint      NOT NULL DEFAULT 1  COMMENT '状态 0禁用 1启用',
  `created_at`  datetime     DEFAULT NULL,
  `updated_at`  datetime     DEFAULT NULL,
  `deleted_at`  datetime     DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_parent` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='商品分类';
```

> 表名带 `md_` 前缀，但 Model 中 `$table` 写**不含前缀**的名字，框架自动拼接。

---

## 三、后端开发

### 3.1 Model（数据模型层）

`backend/app/model/goods/GoodsCategory.php`

```php
<?php
declare(strict_types=1);

namespace app\model\goods;

use app\enum\common\EnabledStatus;
use core\foundation\base\BaseModel;

/**
 * 商品分类模型
 */
class GoodsCategory extends BaseModel
{
    /** 数据表名称（不含前缀） */
    protected $table = 'goods_category';

    /** 数据表主键 */
    protected $primaryKey = 'id';

    /** 可批量赋值的字段 */
    protected $fillable = [
        'id',
        'name',
        'parent_id',
        'description',
        'sort',
        'enabled',
        'created_at',
        'updated_at',
    ];

    /** 字段类型转换：ID 转字符串，避免 JS 大整数精度丢失 */
    protected $casts = [
        'id' => 'string',
    ];

    /** 追加字段 */
    protected $appends = [
        'enabled_text',
    ];

    /** 获取状态文本 */
    public function getEnabledTextAttribute(): string
    {
        return EnabledStatus::tryFrom($this->enabled)?->label() ?? '未知';
    }
}
```

**要点**：

| 约定 | 说明 |
| --- | --- |
| 继承 `core\foundation\base\BaseModel` | 统一基类 |
| `$table` 不含前缀 | 框架自动加 `DB_PREFIX` |
| `$casts` 中 `'id' => 'string'` | **必须**，防止前端 JS 大整数精度丢失 |
| `$appends` + 访问器 | 输出状态文本等衍生字段 |
| 枚举用 `app\enum\` | 避免魔法数字 |

### 3.2 DAO（数据访问层）

`backend/app/dao/goods/GoodsCategoryDao.php`

```php
<?php
declare(strict_types=1);

namespace app\dao\goods;

use app\enum\common\EnabledStatus;
use app\model\goods\GoodsCategory;
use core\foundation\base\BaseDao;

/**
 * 商品分类数据访问对象
 */
class GoodsCategoryDao extends BaseDao
{
    /** 设置模型 */
    protected function setModel(): string
    {
        return GoodsCategory::class;
    }

    /** 获取启用的分类列表 */
    public function getEnabledList(): array
    {
        return $this->query()
            ->where('enabled', EnabledStatus::ENABLED->value)
            ->orderBy('sort', 'asc')
            ->get()
            ->toArray();
    }

    /** 判断分类下是否有子级 */
    public function hasChildren(int $id): bool
    {
        return $this->query()->where('parent_id', $id)->exists();
    }
}
```

**要点**：

- 继承 `BaseDao`，仅需实现 `setModel()` 即可获得 `get()` / `find()` / `query()` / 分页等基础能力。
- 只写**查询构造**，不写业务判断。
- 复杂查询用 `$this->query()` 获取查询构造器。

### 3.3 Service（业务服务层）

`backend/app/service/admin/goods/GoodsCategoryService.php`

```php
<?php
declare(strict_types=1);

namespace app\service\admin\goods;

use app\dao\goods\GoodsCategoryDao;
use core\foundation\base\BaseService;
use core\foundation\exception\handler\AdminException;

/**
 * 商品分类服务类
 */
class GoodsCategoryService extends BaseService
{
    /** 构造方法：依赖注入 DAO */
    public function __construct(GoodsCategoryDao $dao)
    {
        $this->dao = $dao;
    }

    /** 获取启用的分类 */
    public function getEnabledList(): array
    {
        return $this->dao->getEnabledList();
    }

    /** 删除前校验：存在子级不允许删除 */
    public function deleteWithCheck(int $id): bool
    {
        if ($this->dao->hasChildren($id)) {
            throw new AdminException('存在子分类，不允许删除');
        }
        return (bool) $this->dao->delete($id);
    }
}
```

**要点**：

| 约定 | 说明 |
| --- | --- |
| 继承 `BaseService` | 获得通用 CRUD 能力 |
| 构造函数注入 DAO 并赋值 `$this->dao` | **关键**，基类方法依赖此属性 |
| 业务校验抛 `AdminException` | 由全局异常处理器统一转为响应 |
| 跨 DAO 调用用 `Container::make()` | 见 `MemberTagService` 范例 |

### 3.4 Validate（参数校验）

`backend/app/adminapi/validate/goods/GoodsCategoryValidate.php`

```php
<?php
declare(strict_types=1);

namespace app\adminapi\validate\goods;

use app\model\goods\GoodsCategory;
use core\foundation\base\BaseValidate;
use Illuminate\Validation\Rule;

/**
 * 商品分类验证器
 */
class GoodsCategoryValidate extends BaseValidate
{
    /** 验证规则 */
    public function rules(): array
    {
        return [
            'name' => [
                'required',
                'max:50',
                Rule::unique(GoodsCategory::class, 'name')
                    ->ignore(request()->route->param('id'), 'id'),
            ],
            'parent_id'   => 'integer|min:0',
            'description' => 'max:255',
            'sort'        => 'integer|min:0',
            'enabled'     => 'in:0,1',
        ];
    }

    /** 验证消息 */
    protected array $messages = [
        'name.required'   => '分类名称不能为空',
        'name.max'        => '分类名称不能超过50个字符',
        'name.unique'     => '分类名称已存在',
        'description.max' => '描述不能超过255个字符',
        'sort.integer'    => '排序必须为整数',
        'sort.min'        => '排序不能小于0',
        'enabled.in'      => '状态值不正确',
    ];

    /** 验证场景 */
    protected array $scenes = [
        'store'  => ['name', 'parent_id', 'description', 'sort', 'enabled'],
        'update' => ['name', 'parent_id', 'description', 'sort', 'enabled'],
    ];
}
```

**要点**：

- 继承 `BaseValidate`，规则语法为 Laravel 校验规则。
- 唯一性校验用 `Rule::unique()->ignore()`，编辑时排除自身。
- `$scenes` 定义场景，控制器按场景触发。

### 3.5 Controller（控制器）

`backend/app/adminapi/controller/goods/GoodsCategoryController.php`

```php
<?php
declare(strict_types=1);

namespace app\adminapi\controller\goods;

use app\adminapi\controller\Crud;
use app\service\admin\goods\GoodsCategoryService;
use support\Container;
use support\Request;
use support\Response;

/**
 * 商品分类控制器
 */
class GoodsCategoryController extends Crud
{
    /** 构造方法 */
    public function __construct()
    {
        $this->service = Container::make(GoodsCategoryService::class);
        parent::__construct();
    }

    /** 获取启用的分类列表 */
    public function enabled(Request $request): Response
    {
        return $this->success($this->service->getEnabledList());
    }
}
```

**要点**：

- 继承 `app\adminapi\controller\Crud`，自动获得 `index` / `show` / `store` / `update` / `destroy` 等标准 CRUD 接口。
- 构造函数用 `Container::make()` 注入 Service 并赋值 `$this->service`。
- 只有**额外接口**才需要手写方法。
- 控制器**不写业务逻辑**，只做转发与响应。

### 3.6 路由

Madong 后台采用约定式路由，控制器放入 `app/adminapi/controller/<域>/` 后自动映射：

| 方法 | 路径 | 对应 |
| --- | --- | --- |
| GET | `/adminapi/goods/category` | `index` 列表 |
| GET | `/adminapi/goods/category/{id}` | `show` 详情 |
| POST | `/adminapi/goods/category` | `store` 新增 |
| PUT | `/adminapi/goods/category/{id}` | `update` 编辑 |
| DELETE | `/adminapi/goods/category` | `destroy` 删除 |
| GET | `/adminapi/goods/category/enabled` | `enabled` 自定义接口 |

需自定义路由时，在 `app/adminapi/route/` 中声明。详见 [后端 → 路由](../backend/basic/route.md)。

### 3.7 重启生效

```bash
cd backend
php start.php restart      # Windows: 重新执行 php windows.php
```

---

## 四、前端开发

### 4.1 类型定义

`template/admin/src/api/goods/category/types.ts`

```ts
export interface GoodsCategory {
  id: string;
  name: string;
  parent_id: number;
  description: string;
  sort: number;
  enabled: number;
  enabled_text?: string;
  created_at?: string;
  updated_at?: string;
}
```

### 4.2 接口定义

`template/admin/src/api/goods/category/index.ts`

```ts
import type { GoodsCategory } from './types';

import BaseService from '#/api/core/base';
import { requestClient } from '#/api/request';

const baseUrl = '/goods/category';

export const GoodsCategoryService = {
  ...BaseService<GoodsCategory>({
    baseUrl,
    allowedMethods: [],
    forbiddenMethods: [],
  }),

  /** 获取启用的分类列表 */
  getEnabledList(): Promise<GoodsCategory[]> {
    return requestClient.get(`${baseUrl}/enabled`);
  },
};
```

**`BaseService` 自动提供的方法**（见 `src/api/core/base.ts`）：

| 方法 | 请求 | 说明 |
| --- | --- | --- |
| `list(params)` | `GET /goods/category` | 列表 |
| `get(id)` | `GET /goods/category/{id}` | 详情 |
| `create(params)` | `POST /goods/category` | 新增 |
| `update(id, params)` | `PUT /goods/category/{id}` | 编辑（支持传对象自动提取 id） |
| `remove(params)` | `DELETE /goods/category` | 批量删除 |
| `delete(id, params)` | `DELETE /goods/category/{id}` | 单条删除 |
| `export(params)` | `POST /goods/category/export` | 导出 |
| `changStatus(id, params)` | `PUT /goods/category/{id}/change-status` | 改状态 |

可通过 `allowedMethods` / `forbiddenMethods` 白/黑名单控制。

### 4.3 CRUD Schema 配置

`template/admin/src/views/goods/category/schemas/index.tsx`

```tsx
import type { CrudSchema } from '#/components/crud/components/types';

import { GoodsCategoryService } from '#/api/goods/category';
import { DictEnum } from '#/enums';
import { $t } from '#/locales';

export const useCrudSchema = (): CrudSchema => {
  return {
    // ========== 接口绑定 ==========
    crudApi: {
      list: GoodsCategoryService.list,
      add: GoodsCategoryService.create,
      edit: GoodsCategoryService.update as any,
      remove: GoodsCategoryService.remove,
      batchRemove: GoodsCategoryService.remove as any,
      view: GoodsCategoryService.get,
    },

    // ========== 功能开关 ==========
    hasAdd: true,
    hasEdit: true,
    hasView: true,
    hasRemove: true,

    // ========== 权限点 ==========
    permissions: {
      add: 'goods:category:create',
      edit: 'goods:category:update',
      remove: 'goods:category:delete',
      view: 'goods:category:read',
    },

    // ========== 表格列 ==========
    columns: [
      { type: 'checkbox', width: 60 },
      {
        field: 'name',
        title: $t('goods.category.table.columns.name'),
        minWidth: 150,
        align: 'left',
      },
      {
        field: 'description',
        title: $t('goods.category.table.columns.description'),
        minWidth: 200,
        align: 'left',
      },
      {
        field: 'sort',
        title: $t('goods.category.table.columns.sort'),
        minWidth: 80,
      },
      {
        field: 'enabled',
        title: $t('goods.category.table.columns.enabled'),
        minWidth: 80,
        cellRender: {
          name: 'CellDictTag',
          attrs: { code: DictEnum.SYS_ENABLED_STATUS },
        },
      },
      {
        field: 'created_at',
        title: $t('goods.category.table.columns.created_at'),
        minWidth: 160,
        align: 'center',
        formatter: 'formatDateTime',
      },
    ],

    // ========== 搜索表单 ==========
    searchForm: {
      enabled: true,
      collapsed: true,
      collapsedRows: 2,
      schema: [
        {
          component: 'Input',
          fieldName: 'LINK_name',      // LINK_ 前缀 = 模糊查询
          label: $t('goods.category.table.search.name'),
        },
        {
          component: 'ApiDict',
          fieldName: 'EQ_enabled',     // EQ_ 前缀 = 精确匹配
          label: $t('goods.category.table.search.enabled'),
          componentProps: {
            code: DictEnum.SYS_ENABLED_STATUS,
            clearable: true,
          },
        },
      ],
    },

    // ========== 新增/编辑弹窗 ==========
    formDialog: {
      enabled: true,
      title: $t('goods.category.title'),
      width: 'w-[40%]',
      wrapperClass: 'grid-cols-1',
      commonConfig: { labelWidth: 100 },
      schema: [
        {
          fieldName: 'id',
          label: 'ID',
          component: 'Input',
          dependencies: { show: false, triggerFields: ['id'] },  // 隐藏
        },
        {
          fieldName: 'name',
          label: $t('goods.category.form.name'),
          component: 'Input',
          rules: 'required',
        },
        {
          fieldName: 'sort',
          label: $t('goods.category.form.sort'),
          component: 'InputNumber',
          defaultValue: 0,
        },
        {
          fieldName: 'enabled',
          label: $t('goods.category.form.enabled'),
          component: 'ApiDict',
          defaultValue: 1,
          componentProps: {
            code: DictEnum.SYS_ENABLED_STATUS,
            renderType: 'RadioGroup',
            isBtn: true,
          },
        },
        {
          fieldName: 'description',
          label: $t('goods.category.form.description'),
          component: 'Textarea',
          componentProps: { rows: 4 },
        },
      ],
    },
  };
};
```

**查询字段前缀约定**（后端自动解析）：

| 前缀 | 含义 | 示例 |
| --- | --- | --- |
| `LINK_` | 模糊查询 `LIKE %x%` | `LINK_name` |
| `EQ_` | 精确匹配 `=` | `EQ_enabled` |

> ⚠️ `component` 字段填的是**抽象组件类型**（`Input` / `ApiDict` / `Textarea`），由 `src/adapter/component/index.ts` 映射到具体 UI 库。这是多套 UI 复用同一份 Schema 的关键。详见 [UI 适配层设计](../frontend/common/ui-adapter.md)。

### 4.4 页面

`template/admin/src/views/goods/category/index.vue`

```vue
<script setup lang="ts">
import { useCrud } from '#/adapter/crud';
import { Page } from '#/components/page';

import { useCrudSchema } from './schemas';

const [BasicCrud, crudApi] = useCrud({
  ...useCrudSchema(),
  tableActionColumn: {
    width: 200,
  },
});
</script>

<template>
  <Page auto-content-height>
    <BasicCrud />
  </Page>
</template>
```

就这么简单——`useCrud` 返回渲染组件与操作 API，Schema 驱动一切。

### 4.5 添加自定义行操作（可选）

```vue
<script setup lang="ts">
import { ref } from 'vue';

import { useCrud } from '#/adapter/crud';
import { Page } from '#/components/page';
import { $t } from '#/locales';

import { useCrudSchema } from './schemas';

const [BasicCrud, crudApi] = useCrud({
  ...useCrudSchema(),
  tableActionColumn: { width: 320 },

  // 行内按钮
  tableActions: [
    {
      label: '查看商品',
      type: 'primary',
      link: true,
      auth: 'goods:category:goods_list',    // 权限点
      icon: 'ant-design:shop-outlined',
      onClick: (_e: any, row: any) => {
        console.log('查看', row);
      },
    },
  ],

  // 下拉菜单按钮
  dropDownActions: [
    {
      label: $t('common.crud.edit'),
      auth: 'goods:category:update',
      icon: 'ant-design:edit-outlined',
      onClick: (_e: any, row: any) => {
        crudApi.openEditDialog(row);
      },
    },
  ],
});
</script>

<template>
  <Page auto-content-height>
    <BasicCrud />
  </Page>
</template>
```

### 4.6 国际化

`template/admin/src/lang/zh-CN/goods.json`

```json
{
  "category": {
    "title": "商品分类",
    "table": {
      "columns": {
        "name": "分类名称",
        "description": "描述",
        "sort": "排序",
        "enabled": "状态",
        "created_at": "创建时间"
      },
      "search": {
        "name": "分类名称",
        "enabled": "状态"
      }
    },
    "form": {
      "name": "分类名称",
      "sort": "排序",
      "enabled": "状态",
      "description": "描述"
    }
  }
}
```

英文包同理放在 `src/lang/en-US/goods.json`。

---

## 五、配置菜单与权限

### 5.1 添加菜单

登录后台 → **系统管理 → 菜单管理** → 新增：

| 字段 | 值 |
| --- | --- |
| 菜单名称 | 商品分类 |
| 路由路径 | `/goods/category` |
| 组件路径 | `/goods/category/index` |
| 菜单类型 | 菜单 |

### 5.2 添加权限按钮

在该菜单下新增按钮权限：

| 名称 | 权限标识 |
| --- | --- |
| 查询 | `goods:category:read` |
| 新增 | `goods:category:create` |
| 编辑 | `goods:category:update` |
| 删除 | `goods:category:delete` |

> 权限标识需与 Schema 中 `permissions` 及页面 `auth` 字段**完全一致**。

### 5.3 分配角色

**系统管理 → 角色管理** → 编辑角色 → 勾选新菜单与按钮权限 → 保存。

重新登录即可看到菜单。

---

## 六、验证

1. 后端重启完成。
2. 前端 `pnpm dev` 运行中。
3. 登录后台，进入「商品分类」菜单。
4. 逐项测试：列表加载、搜索、新增、编辑、删除。
5. 打开浏览器 Network，确认请求走 `/adminapi/goods/category`。

---

## 七、开发流程总结

```
① 建表
      ↓
② 后端：Model → DAO → Service → Validate → Controller
      ↓
③ 重启后端
      ↓
④ 前端：types → api → schemas → index.vue
      ↓
⑤ 国际化语言包
      ↓
⑥ 后台配置菜单 + 权限 + 角色
      ↓
⑦ 验证
```

**层级职责速记**：

| 层 | 只做一件事 |
| --- | --- |
| Model | 字段映射、关联、访问器 |
| DAO | 查询构造 |
| Service | 业务逻辑、事务、异常 |
| Validate | 参数校验 |
| Controller | 接收参数、返回响应 |
| api/ | 声明接口 |
| schemas/ | 声明表格/表单/权限 |
| index.vue | 组装页面 |

---

## 八、下一步

- 用[代码生成器](../dev-guide/codegen.md)自动生成以上所有骨架
- 深入 [后端分层设计](../backend/architecture/layers.md)
- 深入 [前端 CRUD 组件](../frontend/admin-ele/table.md)
- 查看 [开发规范](../dev-guide/index.md)
