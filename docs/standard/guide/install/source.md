# 2.1 源码获取与下载

Madong 采用「后端服务端 + 前端模板」分离的仓库结构：后端主仓库只包含 `backend/`，`template/admin`、`template/web` 等前端工程需要从独立仓库单独获取。安装前请先按本章把源码准备到工作区。

## 2.1.1 仓库地址一览

以下地址与 `backend/config/install.php` 的 `download.mirrors` 配置一致，**默认使用 GitHub**，网络受限时切换到 Gitee / GitCode 镜像。

| 模块 | GitHub | Gitee 镜像 | GitCode 镜像 | 落地目录 |
| --- | --- | --- | --- | --- |
| 服务端（主仓库） | `https://github.com/madong-code/madong-admin` | `https://gitee.com/motion-code/madong-admin` | `https://gitcode.com/motion-code/madong-admin` | 项目根目录 |
| Admin（single） | `https://github.com/madong-code/madong-single` | `https://gitee.com/motion-code/madong-single` | `https://gitcode.com/motion-code/madong-single` | `template/admin` |
| Admin（aura） | `https://github.com/madong-code/madong-aura` | `https://gitee.com/motion-code/madong-aura` | `https://gitcode.com/motion-code/madong-aura` | `template/admin` |
| Web（门户端） | `https://github.com/madong-code/web-nuxt` | `https://gitee.com/motion-code/web-nuxt` | `https://gitcode.com/motion-code/web-nuxt` | `template/web` |
| Skills（可选） | `https://github.com/madong-code/madong-admin-saas-skills` | `https://gitee.com/motion-code/madong-admin-saas-skills` | `https://gitcode.com/motion-code/madong-admin-saas-skills` | `skills/` |

> - 后台提供 **single / aura 两套 UI，任选其一**，下载命令会把两者统一落到 `template/admin`。
> - Skills 仓库地址以 `backend/config/install.php` 为准（`madong-admin-saas-skills`）；旧文档中的 `madong-admin-skills` 已废弃。
> - 标准版只包含 admin / web 两端，不引入多租户版的 mono / platform 等模块。

## 2.1.2 方式一：命令下载（推荐）

后端安装完 Composer 依赖后，在 `backend/` 目录执行：

```bash
cd backend

# 下载 admin + web（admin 默认取 single 仓库）
php webman madong-download:template

# 只下载管理端 / 门户端
php webman madong-download:template -a
php webman madong-download:template -w

# 管理端改用 aura（仍然落到 template/admin）
php webman madong-download:template -a --admin-variant=aura

# 使用国内镜像
php webman madong-download:template --mirror=gitee
php webman madong-download:template --mirror=gitcode

# 使用 ZIP 归档下载（不包含 .git，无法 git pull 更新）
php webman madong-download:template --method=zip

# 指定分支 / 目标目录已存在时强制更新 / 额外下载 skills
php webman madong-download:template -b develop
php webman madong-download:template -f
php webman madong-download:template -s
```

### 选项说明

| 选项 | 说明 |
| --- | --- |
| `-a`, `--admin` | 只下载管理端模板到 `template/admin` |
| `-w`, `--web` | 只下载门户端模板到 `template/web` |
| `-s`, `--skills` | 额外下载 skills 模板到 `skills/` |
| `--admin-variant` | 管理端 UI 来源：`single`（默认）/ `aura`，二者均落到 `template/admin` |
| `--mirror` | 下载源：`github`（默认）/ `gitee` / `gitcode` |
| `--method` | 下载方式：`git`（默认）/ `zip` |
| `-b`, `--branch` | Git 分支，默认 `main` |
| `-f`, `--force` | 目标目录已存在时强制更新 |

### 默认行为

| 配置项 | 默认值 | 说明 |
| --- | --- | --- |
| 下载源 | GitHub | 默认不自动回退到其他镜像，需通过 `--mirror` 手动切换 |
| 下载方式 | `git` | 克隆后保留 `.git`，后续可直接在模板目录 `git pull` 更新；`zip` 方式不含 `.git` |
| 分支 | `main` | 可用 `-b` 指定其他分支 |
| 管理端 UI | `single` | 可用 `--admin-variant=aura` 切换 |
| 落地目录 | `template/admin`、`template/web` | 与前端工程目录约定一致 |

> 命令实现见 `backend/app/command/install/DownloadCommand.php`，配置见 `backend/config/install.php` 的 `download` 段。
>
> **注意**：旧版 `backend/README.md` 中出现的 `madong-download:frontend` 并不存在，请使用 `madong-download:template`。

## 2.1.3 方式二：手动克隆或下载 ZIP

如果需要在命令之外自行控制版本，可直接克隆仓库：

```bash
# 1. 后端主仓库
git clone https://github.com/madong-code/madong-admin.git madong
cd madong

# 2. 管理端：single / aura 二选一
git clone https://github.com/madong-code/madong-single.git template/admin
# 或：git clone https://github.com/madong-code/madong-aura.git template/admin

# 3. 门户端
git clone https://github.com/madong-code/web-nuxt.git template/web
```

若目标目录已存在且非空，请先删除或清空后再克隆；也可以克隆到临时目录后手动拷贝内容。

ZIP 归档地址格式（`<path>` 为 `madong-code/madong-single` 这类仓库路径，`<branch>` 默认 `main`）：

| 平台 | 归档地址模板 |
| --- | --- |
| GitHub | `https://github.com/{path}/archive/refs/heads/{branch}.zip` |
| Gitee | `https://gitee.com/{path}/repository/archive/{branch}.zip` |
| GitCode | `https://gitcode.com/{path}/archive/{branch}.zip` |

例如 single 后台：`https://github.com/madong-code/madong-single/archive/refs/heads/main.zip`。下载解压后把内容放入 `template/admin` 即可。

## 2.1.4 获取完成后的目录结构

```
madong/
├── backend/          # 后端服务端（主仓库）
├── template/
│   ├── admin/        # 管理端（single 或 aura，二选一）
│   └── web/          # 门户端
└── skills/           # 可选附加资源
```

> 服务端与前端都是独立 Git 仓库，后续升级请分别处理，详见 [5.5 升级与合并](../dev-guide/upgrade.md)。
>
> 下一节：[2.2 环境要求](environment.md)
