# 1.3 整体架构

## 1.3.1 部署形态

```
                    ┌──────────────────────────┐
   浏览器 ──────────▶│  Nginx / 反向代理          │
                    └───────────┬──────────────┘
                                │
         ┌──────────────────────┼──────────────────────┐
         │                      │                      │
   静态资源                  /api/*               /app/* (WS)
         │                      │                      │
┌────────▼────────┐    ┌────────▼────────┐    ┌────────▼────────┐
│ admin (dist)    │    │ Webman HTTP     │    │ webman/push     │
│ web   (Nuxt)    │    │ 进程组           │    │ WebSocket 进程   │
│ install (dist)  │    └────────┬────────┘    └─────────────────┘
└─────────────────┘             │
                    ┌───────────┼───────────┐
                    │           │           │
               ┌────▼───┐  ┌────▼───┐  ┌────▼─────┐
               │ MySQL  │  │ Redis  │  │ 对象存储  │
               └────────┘  └────────┘  └──────────┘
```

后端是**常驻内存的多进程模型**，进程编排在 `backend/config/process.php`：HTTP 进程、监控进程、队列消费进程、定时任务进程、推送进程各司其职。

## 1.3.2 后端分层

Madong 极速后台开发框架采用严格的四层结构，每层只能向下依赖：

```
HTTP Request
    │
    ▼
┌─────────────────────────────────────────────────┐
│ Middleware  认证 / 租户 / 语言 / 限流 / 跨域        │
└──────────────────────┬──────────────────────────┘
                       ▼
┌─────────────────────────────────────────────────┐
│ Controller  参数接收、校验触发、响应封装             │
│  app/adminapi/controller  app/api/controller     │
│  继承 Crud / Base                                 │
└──────────────────────┬──────────────────────────┘
                       ▼
┌─────────────────────────────────────────────────┐
│ Service     业务编排、事务、跨模块协作               │
│  app/service/**                                  │
└──────────────────────┬──────────────────────────┘
                       ▼
┌─────────────────────────────────────────────────┐
│ Dao         数据访问、查询条件拼装                   │
│  app/dao/**                                      │
└──────────────────────┬──────────────────────────┘
                       ▼
┌─────────────────────────────────────────────────┐
│ Model       表映射、字段转换、关联、作用域            │
│  app/model/**   (Eloquent)                       │
└──────────────────────┬──────────────────────────┘
                       ▼
                    MySQL
```

**依赖方向铁律**

- Controller **不得**直接使用 Model / DB 门面
- Service **不得**直接使用 Model，必须经 Dao
- Dao **不得**包含业务判断，只负责取数与拼条件
- Model **不得**反向依赖 Service / Dao

## 1.3.3 内核分域（`backend/core/`）

`core/` 是与具体业务无关的框架能力层，按领域划分：

| 目录 | 职责 |
| --- | --- |
| `core/foundation/` | 地基：`base`（BaseController/BaseService/BaseDao/BaseModel）、`exception`、`interface`、`trait`、`tool`、`config` |
| `core/business/` | 业务型内核：`route`（注解路由派生）、`plugin`（插件机制）、`install`（安装）、`terminal`（**Web 终端**）、`service`、`config` |
| `core/security/` | 安全：`jwt`、`captcha`、`config` |
| `core/infrastructure/` | 基础设施：`cache`、`logger`、`monitor`、`scheduler` |
| `core/communication/` | 通信：`sms`、`email`、`notify`（**消息推送**） |
| `core/io/` | 输入输出：`upload`、`excel`、`uuid` |
| `core/interface/` | 外部接口：`review`（**内容审核**） |

> 业务代码位于 `app/`，内核能力位于 `core/`。二次开发原则上只新增 `app/` 与 `plugin/`，不修改 `core/`。

## 1.3.4 多端划分（`backend/app/`）

| 应用 | 路径 | 面向 | 认证方式 |
| --- | --- | --- | --- |
| `adminapi` | `app/adminapi/` | 后台管理端（`template/admin`） | 管理员 JWT |
| `api` | `app/api/` | 门户端 / 移动端（`template/web`） | 用户 JWT |
| `install` | `app/install/` | 安装向导（`template/install`） | 无（安装完成后由 `install.lock` 锁定） |

三端**共享**同一套 `app/service`、`app/dao`、`app/model`，仅控制器与中间件不同。这样业务逻辑只写一次，多端复用。

## 1.3.5 请求生命周期

1. **进程启动** — `start.php`（Linux）/ `windows.php`（Windows）读取 `config/process.php` 拉起各进程。
2. **引导** — `app/bootstrap/` 下的引导类依次执行（容器、数据库、事件、插件扫描等）。
3. **路由匹配** — `config/route.php` 与 `app/adminapi/config/route.php` 生效；大部分接口路由由 **OpenAPI 注解自动派生**，无需手写。
4. **中间件链** — `config/middleware.php` 定义全局与分应用中间件（鉴权、租户、语言、日志…）。
5. **控制器** — 继承 `Crud` 的控制器直接获得 `index/save/update/destroy/read` 等标准动作。
6. **Service / Dao / Model** — 逐层下沉完成业务。
7. **统一响应** — 由基类封装为 `{ code, msg, data }` 结构返回。
8. **异常** — 未捕获异常交由 `app/exception/` 的处理器转换为标准错误响应。

## 1.3.6 前后端协作

```
template/admin  ──axios──▶  /adminapi/*   ──▶ app/adminapi
template/web    ──$fetch─▶  /api/*        ──▶ app/api
template/*      ◀─WebSocket─  /app/{key}  ──▶ webman/push
```

- 统一响应体：`{ code, msg, data }`，`code === 0`（或约定成功码）视为成功。
- 鉴权头：`Authorization`（可由 `.env` 中 `*_REQUEST_HEADER_TOKEN_KEY` 配置）。
- 多租户头：`X-Tenant-Id`。
- 端标识头：`Channel`（如 `pc`）。

> 下一节：[1.4 目录结构](directory.md)
