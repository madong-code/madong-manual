# 开发规范 · 安全

---

## 1. 认证与授权

- 所有后台接口经 `AccessTokenMiddleware` + `PermissionMiddleware`（见 [`backend/basic/middleware.md`](../backend/basic/middleware.md)）。
- 每个接口加 `#[Permission(code)]`，无权限码即任何人可访问（危险）。
- JWT 密钥仅存 `.env`，必须由安装向导随机生成（≥32 字符）；禁止在配置或代码中提供默认/回退密钥，缺失或占位值一律 fail-fast。
- 存量部署用 `php webman jwt:secret` 生成，`--force` 强制轮换；轮换后所有旧令牌失效。`core/security/jwt/JwtSecret` 是密钥生成与校验的唯一入口。
- 平台端身份判定必须基于 `JwtToken::getVerifiedPayload()`（签名 + 黑名单 + 令牌类型 + 用户存在 + JTI 注册复核），不得直接信任 `getPayloadFromRequest()` 中的 `admin_types`。
- 登出加入 Redis 黑名单。
- 超管 `superCodes=['*']` 谨慎分配。

---

## 2. 注入防护

- 一律用 ORM（ThinkORM）/参数绑定，禁止字符串拼接 SQL。
- 搜索条件经 `search()` 前缀解析，不直接拼接到 SQL。

---

## 3. 越权防护

- 写操作字段白名单：`inputFilter($all, $allow)`。
- 更新场景唯一校验 `Rule::unique` 自动 `ignore($id)`。
- 数据权限经 `AccessPermissionScope` 过滤（租户/部门）。

---

## 4. 上传安全

- 文件类型白名单、大小限制、重命名存储（见 [`backend/modules/upload.md`](../backend/modules/upload.md)）。
- 对象存储用签名 URL，避免公开写。

---

## 5. 输入校验

- 入参 Validate + `scene`；前端 `rules` 二次校验（防绕过）。
- 富文本/HTML 输出做 XSS 过滤。
- `filterWord` 只是 XSS/SQL 辅助过滤：`all()`/`input()` 不经过它，黑名单可被变形载荷绕过，绝不可作为路径安全边界。

---

## 6. 日志与审计

- 关键写操作经 `OperationMiddleware` + `OperationLogListener` 记录。
- 日志不打印密码/token/密钥，拒绝访问时只记录原因，不记录完整用户输入。
- 异常全局捕获，生产不泄露堆栈。

---

## 7. 依赖安全

- 定期 `composer audit` / `pnpm audit`。
- 不引入未审核的第三方包；内核 `core/` 不擅自改。

---

## 8. 文件下载与导出

- 任何由请求参数拼接的文件路径，必须经 `core/io/excel/ExportPathGuard` 这类白名单守卫：归一化、`realpath()`、带目录分隔符的根前缀比较、扩展名与文件存在校验。
- 导出文件只允许放在 `runtime/exports/`；控制器与队列消费者必须各自调用守卫，不能只信任上游。
- 队列消息使用字段白名单，仅传递已校验的相对文件名，禁止透传 `$request->all()`。
- 下载响应名与导出磁盘文件名需过滤路径符、CRLF 与 `..`；下载链接查询参数必须 URL 编码。
