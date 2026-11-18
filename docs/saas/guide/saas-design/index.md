# 10. SaaS 设计

本章介绍 Madong-Saas 的 **SaaS 多租户设计**。Madong-Saas 是一套同时支持**单租户标准版**与**多租户 SaaS 版**的后台管理系统。

## 核心概念

### 什么是 Madong-Saas

Madong-Saas 基于 Webman + Vue（mono），提供完整的 RBAC 权限、菜单、插件、多语言等能力，并在此基础上扩展了 **多租户（SaaS）** 支持：一个平台可托管多个独立租户，每个租户拥有独立的用户、数据与订阅。

### 两种运行模式

| 模式 | 说明 | 适用场景 |
| --- | --- | --- |
| **标准版（Standard）** | 单租户，不启用租户隔离，所有数据共享 | 私有部署、单客户 |
| **多租户版（SaaS）** | 平台级，多租户隔离，支持订阅计费 | 云服务、多客户托管 |

通过环境变量 `APP_TENANT_ENABLED` 一键切换：

```env
# 标准版（默认）
APP_TENANT_ENABLED=false

# 多租户版
APP_TENANT_ENABLED=true
```

多租户模式下 `enable=true`，自动启用 `field`（字段隔离）模式；关闭则回到 `single` 模式。

## 租户（Tenant）

- 租户是数据隔离与订阅计费的基本单元
- 每个租户有独立的 `tenant_id`，贯穿数据表、请求头、缓存、日志
- 租户模型：`app\model\tenant\Tenant`
- 管理员与租户通过 `sys_admin.tenant_id` 直接关联

## 隔离模式

Madong-Saas 支持两种租户数据隔离模式：

| 模式 | 隔离方式 | 数据形态 |
| --- | --- | --- |
| **字段隔离（field）** | 共享表 + `tenant_id` 字段区分 | 所有租户共用一张表 |
| **库隔离（database）** | 每租户独立数据库 | 物理隔离，数据安全最高 |

新建租户时的默认隔离策略由 `config/tenant.php` 的 `default_mode` 决定（默认 `field`），也支持按模块配置隔离模式（`module_modes`）。

详见 [租户隔离模式](./tenancy.md)。

## 订阅与套餐

多租户版支持**功能订阅**：

- 套餐（Subscription）定义了租户可用的权限集合
- 通过 `saas_subscription_permission` 表管理套餐-权限关联
- 订阅有过期检查与宽限期（默认 7 天）

详见 [订阅与套餐](./subscription.md)。

## 平台与租户的边界

Madong-Saas 将**平台级管理**（`platform` 应用）与**租户级后台**（`admin` 应用）分离：

| 应用 | 定位 | 多租户 |
| --- | --- | --- |
| `platform` 平台管理 | 租户、数据库、监控、订阅管理 | 无（平台级） |
| `admin` 后台管理 | 租户内业务运营 | 有（`X-Tenant-Id`） |

- 平台应用管理租户生命周期、订阅计费
- 后台应用在租户上下文内运行业务，请求自动注入 `X-Tenant-Id`

## 快速导航

- [租户隔离模式](./tenancy.md) - 单租户 / 字段隔离 / 库隔离
- [标准版与多租户版](./standard-vs-saas.md) - 两种模式对比与切换
- [订阅与套餐](./subscription.md) - 功能订阅与计费
- [三形态共用仓库整合方案](./shared-repo-integration.md) - 标准版/SaaS/库隔离共用后端的整合实证与迁移策略
