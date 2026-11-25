# 后端开发

Madong 极速后台开发框架的后端基于 **Webman 2.2**（常驻内存多进程 PHP 框架，要求 PHP >= 8.2），数据库使用 **Laravel Illuminate Database ^11.33**，业务代码遵循严格的 **四层架构**：

```
Controller（控制器） → Service（服务层） → Dao（数据访问） → Model（模型）
```

- 依赖只能向下，禁止反向调用（如 Dao 不能依赖 Service，Model 不感知上层）。
- 路由通过 **OpenAPI 注解**（`#[OA\Get/Post/...]`）自动扫描注册，无需手写路由表。
- 接口文档由 `webman-tech/swagger` + `madong/swagger` 自动生成，访问 `/adminapi/openapi`。
- 后台接口统一前缀 `/adminapi`，前台接口前缀 `/api`。

本章分三部分：

- **4-1 入门**：概述、快速开始、架构概览、模块结构、配置体系、数据库操作、国际化
- **4-2 基础功能**：控制器、服务层、Dao、Model、验证层、DTO/Schemas、权限管理
- **4-3 高级功能**：Web 终端、应用插件、查询构造器、消息推送、内容审核

> 框架核心代码位于 `backend/core/`，**二次开发请勿修改**；业务代码写在 `backend/app/` 下。
