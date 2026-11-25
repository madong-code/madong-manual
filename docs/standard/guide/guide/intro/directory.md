# 1.4 目录结构

## 1.4.1 仓库根目录

```
madong/
├── backend/            后端服务（Webman）
├── template/
│   ├── admin/          后台管理端（Vue 3 + Vite）
│   ├── web/            门户端（Nuxt 4）
│   └── install/        安装向导（Vue 3 + Vite）
├── skills/             AI 编码助手规约集
└── docs/               本文档（docsify）
```

## 1.4.2 后端 `backend/`

```
backend/
├── app/                        业务代码（PSR-4: app\）
│   ├── adminapi/               后台端应用
│   │   ├── config/             该应用独立配置（route.php、middleware…）
│   │   ├── controller/         控制器（含基类 Base.php / Crud.php）
│   │   ├── middleware/         后台端中间件
│   │   └── validate/           后台端验证器
│   ├── api/                    门户/移动端应用
│   ├── install/                安装应用
│   ├── service/                服务层（三端共享）
│   ├── dao/                    数据访问层（三端共享）
│   ├── model/                  模型层（三端共享，Eloquent）
│   ├── adminapi/schema/        OpenAPI Schema / DTO（request、response 子目录）
│   ├── enum/                   枚举
│   ├── event/                  事件与监听
│   ├── exception/              异常处理器
│   ├── queue/                  队列任务
│   ├── process/                自定义进程
│   ├── bootstrap/              启动引导
│   ├── command/                命令行
│   └── functions.php           业务辅助函数
├── core/                       框架内核（PSR-4: core\）
│   ├── foundation/             base / exception / interface / trait / tool / config
│   ├── business/               route / plugin / install / terminal / service / config
│   ├── security/               jwt / captcha
│   ├── infrastructure/         cache / logger / monitor / scheduler
│   ├── communication/          sms / email / notify
│   ├── io/                     upload / excel / uuid
│   └── interface/              review（内容审核）
├── config/                     全局配置
├── plugin/                     应用插件（每个子目录 = 一个插件）
├── extend/                     PSR-0 扩展类库
├── support/                    helpers.php 等支撑文件
├── resource/                   迁移、种子、模板等资源
├── public/                     对外静态目录（上传文件等）
├── runtime/                    运行时（日志、缓存、编译产物）
├── vendor/                     Composer 依赖
├── .env                        环境变量
├── composer.json
├── phinx.php                   迁移配置
├── start.php                   Linux/macOS 启动入口
└── windows.php                 Windows 启动入口
```

### 关键约定

- **业务写在 `app/`，能力沉在 `core/`。** 二开不要改 `core/`。
- `app/service`、`app/dao`、`app/model` 三端共享，避免重复实现。
- `plugin/` 下每个目录是一个可独立装卸的插件，框架启动时自动扫描注册。

## 1.4.3 后台端 `template/admin/`

```
template/admin/
├── src/
│   ├── core/           内联的 Vben 内核（布局、组件、hooks、工具、locales…）
│   ├── api/            接口定义，按后端模块镜像组织
│   ├── adapter/        UI 适配层（form.ts、vxe-table.ts 等全局默认配置）
│   ├── components/     业务通用组件
│   ├── views/          页面
│   ├── router/         路由（静态路由 + 动态路由 + 守卫）
│   ├── store/          Pinia 状态
│   ├── layouts/        布局
│   ├── locales/        国际化入口
│   ├── lang/           语言包（json）
│   ├── plugin/         前端插件（如 portal）
│   ├── enums/          枚举常量
│   ├── types/          全局类型
│   ├── utils/          工具函数
│   ├── assets/         静态资源
│   ├── app.vue         根组件
│   ├── main.ts         应用入口
│   ├── bootstrap.ts    启动引导
│   └── preferences.ts  偏好设置默认值
├── build/              构建脚本与 Nginx/Docker 模板
├── tooling/            工程化工具包（eslint/ts/vite 等内部配置）
├── lib/                本地依赖包
├── public/             公共静态资源
├── vite.config.ts
├── package.json
└── pnpm-workspace.yaml
```

> `src/core/` 是被内联进项目的框架内核，**不建议直接修改**；业务改动集中在 `api`/`views`/`router`/`store`/`plugin`。

## 1.4.4 门户端 `template/web/`

```
template/web/
├── src/
│   ├── pages/          文件路由页面
│   ├── layouts/        布局
│   ├── components/     组件
│   ├── composables/    组合式函数
│   ├── stores/         Pinia
│   ├── assets/         资源与样式
│   ├── plugins/        Nuxt 插件
│   ├── middleware/     路由中间件
│   └── app.vue
├── public/
├── nuxt.config.ts      srcDir: 'src'、ssr、模块与主题配置
├── uno.config.ts
└── package.json
```

## 1.4.5 安装端 `template/install/`

标准 Vue 3 + Vite 结构，用于引导式安装：环境检测 → 数据库配置 → 建表导数 → 管理员设置 → 完成（写入 `install.lock`）。

## 1.4.6 Skills `skills/`

按“后端 / 前端 + 主题”组织的 Markdown 规约集，供 AI 编码助手在生成代码时遵循项目约定，详见 [6. Skills](../skills/index.md)。

> 下一节：[1.5 核心特性](features.md)
