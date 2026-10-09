-- ============================================================================
-- 数据迁移脚本：madong_saas_portal（SaaS 版） → madong_portal（独立版）
--
-- 范围：
--   A. 在目标库 madong_portal 建表 27 张（DDL 取自 madong_single 开发库实际结构）
--      member 系 12 张 + portal_forum 系 15 张（poll/report/sponsor 只建表不迁数据）
--   B. 会员数据迁移（用户/等级/标签/积分流水/签到）
--   C. 门户问答数据迁移（md_portal_ask_* → md_portal_forum_*，字段映射见各段注释）
--
-- 原则：
--   * 全程不改动原有 ID（含会员 ID），论坛关联关系不变
--   * 源表统一多 tenant_id 字段（多租户遗留），迁移时剔除
--   * 只读源库，只写目标库
--
-- 幂等性：
--   可重复执行。建表段 DROP TABLE IF EXISTS + CREATE TABLE 重建目标表，
--   数据段全量重灌。中途失败可直接重跑。
--
-- 用法：
--   mysql --host=127.0.0.1 --user=root --password=root \
--         --default-character-set=utf8mb4 < saas_portal_to_portal.sql
-- ============================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

USE madong_portal;

-- ============================================================================
-- A. 建表（结构同步自 madong_single，27 张）
-- ============================================================================

-- ---------- member 系 12 张 ----------

DROP TABLE IF EXISTS madong_portal.md_member;
CREATE TABLE `md_member` (
  `id` bigint NOT NULL COMMENT '雪花ID',
  `username` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '用户名',
  `email` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '邮箱',
  `phone` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '手机号',
  `password` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '密码',
  `nickname` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '昵称',
  `avatar` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '头像',
  `level_id` bigint NOT NULL DEFAULT '1' COMMENT '等级ID',
  `points` int NOT NULL DEFAULT '0' COMMENT '积分',
  `balance` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '余额',
  `gender` tinyint NOT NULL DEFAULT '0' COMMENT '性别: 0-未知 1-男 2-女',
  `birthday` int DEFAULT NULL COMMENT '生日时间戳',
  `last_login_time` int DEFAULT NULL COMMENT '最后登录时间戳',
  `last_login_ip` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '最后登录IP',
  `login_count` int NOT NULL DEFAULT '0' COMMENT '登录次数',
  `enabled` tinyint NOT NULL DEFAULT '1' COMMENT '状态: 1-启用 0-禁用',
  `created_at` int DEFAULT NULL COMMENT '创建时间戳',
  `updated_at` int DEFAULT NULL COMMENT '更新时间戳',
  `deleted_at` int DEFAULT NULL COMMENT '删除时间戳',
  `bio` longtext COLLATE utf8mb4_unicode_ci COMMENT '个人简介',
  PRIMARY KEY (`id`),
  UNIQUE KEY `member_username_unique` (`username`),
  KEY `member_level_id_index` (`level_id`),
  KEY `member_enabled_index` (`enabled`),
  KEY `member_created_at_index` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS madong_portal.md_member_bill;
CREATE TABLE `md_member_bill` (
  `id` bigint NOT NULL COMMENT '雪花ID',
  `member_id` bigint NOT NULL COMMENT '会员ID',
  `type` tinyint NOT NULL COMMENT '类型: 1-收入 2-支出',
  `category` tinyint NOT NULL COMMENT '分类: 1-充值 2-提现 3-订单 4-退款 5-积分 6-签到 99-其他',
  `amount` decimal(10,2) NOT NULL COMMENT '金额',
  `balance` decimal(10,2) DEFAULT NULL COMMENT '余额',
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '描述',
  `order_sn` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '订单号',
  `status` tinyint NOT NULL DEFAULT '0' COMMENT '状态: 0-待处理 1-成功 2-失败',
  `created_at` int DEFAULT NULL COMMENT '创建时间戳',
  `updated_at` int DEFAULT NULL COMMENT '更新时间戳',
  PRIMARY KEY (`id`),
  KEY `member_bill_member_id_index` (`member_id`),
  KEY `member_bill_type_index` (`type`),
  KEY `member_bill_category_index` (`category`),
  KEY `member_bill_status_index` (`status`),
  KEY `member_bill_created_at_index` (`created_at`),
  KEY `member_bill_order_sn_index` (`order_sn`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS madong_portal.md_member_level;
CREATE TABLE `md_member_level` (
  `id` bigint NOT NULL COMMENT '雪花ID',
  `name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '等级名称',
  `level` tinyint NOT NULL COMMENT '等级值',
  `min_points` int NOT NULL DEFAULT '0' COMMENT '最低积分',
  `max_points` int NOT NULL DEFAULT '0' COMMENT '最高积分',
  `discount` decimal(3,2) NOT NULL DEFAULT '1.00' COMMENT '折扣率',
  `icon` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '等级图标',
  `color` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '等级颜色',
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '等级描述',
  `enabled` tinyint NOT NULL DEFAULT '1' COMMENT '状态: 1-启用 0-禁用',
  `created_at` int DEFAULT NULL COMMENT '创建时间戳',
  `updated_at` int DEFAULT NULL COMMENT '更新时间戳',
  PRIMARY KEY (`id`),
  UNIQUE KEY `member_level_name_unique` (`name`),
  KEY `member_level_level_index` (`level`),
  KEY `member_level_enabled_index` (`enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS madong_portal.md_member_menu;
CREATE TABLE `md_member_menu` (
  `id` bigint NOT NULL COMMENT '雪花ID',
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '菜单名称',
  `url` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '菜单链接',
  `icon` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '菜单图标',
  `parent_id` bigint NOT NULL DEFAULT '0' COMMENT '父级ID',
  `level` tinyint NOT NULL DEFAULT '1' COMMENT '级别',
  `type` tinyint NOT NULL DEFAULT '1' COMMENT '菜单类型: 1-普通菜单 2-开通菜单',
  `sort` smallint NOT NULL DEFAULT '0' COMMENT '排序',
  `target` tinyint NOT NULL DEFAULT '2' COMMENT '目标窗口: 1-当前窗口 2-新窗口',
  `price` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '开通价格',
  `is_open` tinyint NOT NULL DEFAULT '0' COMMENT '是否开通: 1-已开通 0-未开通',
  `open_condition` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '开通条件',
  `is_show` tinyint NOT NULL DEFAULT '1' COMMENT '显示状态: 1-显示 0-隐藏',
  `status` tinyint NOT NULL DEFAULT '1' COMMENT '状态: 1-启用 0-禁用',
  `created_at` int DEFAULT NULL COMMENT '创建时间戳',
  `updated_at` int DEFAULT NULL COMMENT '更新时间戳',
  `deleted_at` int DEFAULT NULL COMMENT '删除时间戳',
  PRIMARY KEY (`id`),
  KEY `member_menu_parent_id_index` (`parent_id`),
  KEY `member_menu_type_index` (`type`),
  KEY `member_menu_sort_index` (`sort`),
  KEY `member_menu_is_open_index` (`is_open`),
  KEY `member_menu_is_show_index` (`is_show`),
  KEY `member_menu_status_index` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS madong_portal.md_member_points;
CREATE TABLE `md_member_points` (
  `id` bigint NOT NULL COMMENT '主键ID',
  `member_id` bigint NOT NULL COMMENT '会员ID',
  `points` int NOT NULL DEFAULT '0' COMMENT '积分数量',
  `balance` int DEFAULT NULL COMMENT '操作后积分',
  `type` tinyint DEFAULT NULL COMMENT '积分类型: 1-增加 2-减少 3-调整',
  `source` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '积分来源',
  `remark` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '备注',
  `operator` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '操作人',
  `order_id` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '订单ID',
  `created_at` int DEFAULT NULL COMMENT '创建时间',
  `updated_at` int DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `member_points_member_id_index` (`member_id`),
  KEY `member_points_type_index` (`type`),
  KEY `member_points_created_at_index` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS madong_portal.md_member_sign;
CREATE TABLE `md_member_sign` (
  `id` bigint NOT NULL COMMENT '雪花ID',
  `member_id` bigint NOT NULL COMMENT '会员ID',
  `sign_date` date DEFAULT NULL COMMENT '签到日期',
  `points` int NOT NULL DEFAULT '0' COMMENT '签到积分',
  `continuous_days` smallint NOT NULL DEFAULT '1' COMMENT '连续签到天数',
  `created_at` int DEFAULT NULL COMMENT '创建时间戳',
  `updated_at` int DEFAULT NULL,
  `device_ip` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `device_ua` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `member_sign_member_id_sign_date_unique` (`member_id`,`sign_date`),
  KEY `member_sign_member_id_index` (`member_id`),
  KEY `member_sign_sign_date_index` (`sign_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS madong_portal.md_member_tag;
CREATE TABLE `md_member_tag` (
  `id` bigint NOT NULL COMMENT '雪花ID',
  `name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '标签名称',
  `color` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '标签颜色',
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '标签描述',
  `sort` smallint NOT NULL DEFAULT '0' COMMENT '排序',
  `enabled` tinyint NOT NULL DEFAULT '1' COMMENT '状态: 1-启用 0-禁用',
  `created_at` int DEFAULT NULL COMMENT '创建时间戳',
  `updated_at` int DEFAULT NULL COMMENT '更新时间戳',
  PRIMARY KEY (`id`),
  UNIQUE KEY `member_tag_name_unique` (`name`),
  KEY `member_tag_sort_index` (`sort`),
  KEY `member_tag_enabled_index` (`enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS madong_portal.md_member_tag_permission;
CREATE TABLE `md_member_tag_permission` (
  `menu_id` bigint NOT NULL COMMENT 'WEB_MENU_ID',
  `tag_id` bigint NOT NULL COMMENT '标签ID',
  PRIMARY KEY (`menu_id`,`tag_id`),
  KEY `member_tag_permission_menu_id_index` (`menu_id`),
  KEY `member_tag_permission_tag_id_index` (`tag_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS madong_portal.md_member_tag_relation;
CREATE TABLE `md_member_tag_relation` (
  `member_id` bigint NOT NULL COMMENT '会员ID',
  `tag_id` bigint NOT NULL COMMENT '标签ID',
  UNIQUE KEY `member_tag_relation_member_id_tag_id_unique` (`member_id`,`tag_id`),
  KEY `member_tag_relation_member_id_index` (`member_id`),
  KEY `member_tag_relation_tag_id_index` (`tag_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS madong_portal.md_member_third_party;
CREATE TABLE `md_member_third_party` (
  `id` bigint NOT NULL COMMENT '主键ID',
  `member_id` bigint NOT NULL COMMENT '会员ID',
  `platform` tinyint NOT NULL DEFAULT '0' COMMENT '平台类型: 1=QQ, 2=微信, 3=微博, 4=抖音',
  `openid` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '第三方OpenID',
  `unionid` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '第三方UnionID',
  `nickname` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '昵称',
  `avatar` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '头像',
  `gender` tinyint NOT NULL DEFAULT '0' COMMENT '性别: 0=未知, 1=男, 2=女',
  `country` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '国家',
  `province` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '省份',
  `city` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '城市',
  `access_token` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '访问令牌',
  `refresh_token` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '刷新令牌',
  `enabled` tinyint NOT NULL DEFAULT '1' COMMENT '状态: 0=禁用, 1=启用',
  `expires_at` int DEFAULT NULL COMMENT '令牌过期时间',
  `created_at` int DEFAULT NULL COMMENT '创建时间',
  `updated_at` int DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS madong_portal.md_member_withdraw;
CREATE TABLE `md_member_withdraw` (
  `id` bigint NOT NULL COMMENT '雪花ID',
  `member_id` bigint NOT NULL COMMENT '会员ID',
  `account_id` bigint DEFAULT NULL COMMENT '提现账号ID',
  `amount` decimal(10,2) NOT NULL COMMENT '提现金额',
  `fee` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '手续费',
  `actual_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '实际到账金额',
  `status` tinyint DEFAULT NULL COMMENT '状态',
  `bank_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '银行名称',
  `bank_account` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '银行账号',
  `bank_cardholder` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '持卡人姓名',
  `order_sn` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '订单号',
  `remark` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '备注',
  `audit_remark` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '审核备注',
  `created_at` int DEFAULT NULL COMMENT '创建时间戳',
  `updated_at` int DEFAULT NULL COMMENT '更新时间戳',
  `audit_at` int DEFAULT NULL COMMENT '审核时间戳',
  PRIMARY KEY (`id`),
  KEY `member_withdraw_member_id_index` (`member_id`),
  KEY `member_withdraw_account_id_index` (`account_id`),
  KEY `member_withdraw_status_index` (`status`),
  KEY `member_withdraw_created_at_index` (`created_at`),
  KEY `member_withdraw_order_sn_index` (`order_sn`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS madong_portal.md_member_withdraw_account;
CREATE TABLE `md_member_withdraw_account` (
  `id` bigint NOT NULL COMMENT '雪花ID',
  `member_id` bigint NOT NULL COMMENT '会员ID',
  `type` tinyint NOT NULL COMMENT '账号类型',
  `bank_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '银行名称',
  `account_name` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '账户名称',
  `account_number` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '账号号码',
  `branch_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '支行名称',
  `is_default` tinyint NOT NULL DEFAULT '0' COMMENT '是否默认: 1-是 0-否',
  `enabled` tinyint NOT NULL DEFAULT '1' COMMENT '状态: 1-启用 0-禁用',
  `created_at` int DEFAULT NULL COMMENT '创建时间戳',
  `updated_at` int DEFAULT NULL COMMENT '更新时间戳',
  `deleted_at` int DEFAULT NULL COMMENT '删除时间戳',
  PRIMARY KEY (`id`),
  KEY `member_withdraw_account_member_id_index` (`member_id`),
  KEY `member_withdraw_account_type_index` (`type`),
  KEY `member_withdraw_account_is_default_index` (`is_default`),
  KEY `member_withdraw_account_enabled_index` (`enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------- portal_forum 系 15 张 ----------

DROP TABLE IF EXISTS madong_portal.md_portal_forum_category;
CREATE TABLE `md_portal_forum_category` (
  `id` bigint NOT NULL,
  `name` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `slug` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `parent_id` bigint NOT NULL DEFAULT '0',
  `sort` int NOT NULL DEFAULT '0' COMMENT '排序',
  `status` tinyint NOT NULL DEFAULT '1' COMMENT '状态',
  `created_at` bigint DEFAULT NULL,
  `updated_at` bigint DEFAULT NULL,
  `deleted_at` bigint DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS madong_portal.md_portal_forum_collection;
CREATE TABLE `md_portal_forum_collection` (
  `member_id` bigint NOT NULL COMMENT '收藏用户ID',
  `topic_id` bigint NOT NULL COMMENT '收藏的话题ID',
  `created_at` bigint DEFAULT NULL COMMENT '收藏时间',
  UNIQUE KEY `ask_collection_unique` (`member_id`,`topic_id`),
  KEY `portal_ask_collection_member_id_index` (`member_id`),
  KEY `portal_ask_collection_question_id_index` (`topic_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS madong_portal.md_portal_forum_comment;
CREATE TABLE `md_portal_forum_comment` (
  `id` bigint NOT NULL COMMENT '雪花ID主键',
  `content` text COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '评论内容',
  `parent_type` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '父对象类型',
  `parent_id` bigint NOT NULL COMMENT '父对象ID',
  `member_id` bigint NOT NULL COMMENT '评论用户ID',
  `status` tinyint NOT NULL DEFAULT '0' COMMENT '审核状态:0待审 1通过 2拒绝 3取消 4审批中',
  `reply_to` bigint NOT NULL DEFAULT '0' COMMENT '回复的目标评论ID',
  `deleted_at` bigint DEFAULT NULL COMMENT '删除时间',
  `created_at` bigint DEFAULT NULL COMMENT '创建时间',
  `updated_at` bigint DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `portal_ask_comment_parent_type_parent_id_index` (`parent_type`,`parent_id`),
  KEY `portal_ask_comment_member_id_index` (`member_id`),
  KEY `portal_ask_comment_status_index` (`status`),
  KEY `portal_ask_comment_created_at_index` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS madong_portal.md_portal_forum_dislike;
CREATE TABLE `md_portal_forum_dislike` (
  `id` bigint NOT NULL COMMENT '雪花ID主键',
  `member_id` bigint NOT NULL COMMENT '用户ID',
  `target_type` enum('topic','reply','comment') COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '目标类型:topic|reply|comment',
  `target_id` bigint NOT NULL COMMENT '目标ID',
  `created_at` bigint DEFAULT NULL COMMENT '创建时间',
  `updated_at` bigint DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `forum_dislike_unique` (`member_id`,`target_type`,`target_id`),
  KEY `portal_forum_dislike_target_type_target_id_index` (`target_type`,`target_id`),
  KEY `portal_forum_dislike_member_id_index` (`member_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS madong_portal.md_portal_forum_integral_type;
CREATE TABLE `md_portal_forum_integral_type` (
  `id` bigint NOT NULL COMMENT '类型ID',
  `type_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '类型标识',
  `type_name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '类型名称',
  `change_direction` enum('earn','spend') COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '变动方向',
  `default_value` tinyint NOT NULL DEFAULT '0' COMMENT '默认变动值',
  `daily_limit` smallint DEFAULT '0' COMMENT '单日上限',
  `related_entity_type` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '关联对象类型',
  `description` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '类型描述',
  PRIMARY KEY (`id`),
  UNIQUE KEY `portal_forum_integral_type_type_code_unique` (`type_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS madong_portal.md_portal_forum_like;
CREATE TABLE `md_portal_forum_like` (
  `id` bigint NOT NULL COMMENT '雪花ID主键',
  `member_id` bigint NOT NULL COMMENT '点赞用户ID',
  `target_type` enum('topic','reply','comment') COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '目标类型:topic|reply|comment',
  `target_id` bigint NOT NULL COMMENT '目标ID',
  `created_at` bigint DEFAULT NULL COMMENT '创建时间',
  `updated_at` bigint DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `ask_like_unique` (`member_id`,`target_type`,`target_id`),
  KEY `portal_ask_like_target_type_target_id_index` (`target_type`,`target_id`),
  KEY `portal_ask_like_member_id_index` (`member_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS madong_portal.md_portal_forum_poll;
CREATE TABLE `md_portal_forum_poll` (
  `id` bigint NOT NULL COMMENT '雪花ID主键',
  `topic_id` bigint NOT NULL COMMENT '关联话题ID',
  `title` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '投票标题',
  `vote_type` enum('single','multiple') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'single' COMMENT '投票类型:single单选 multiple多选',
  `max_options` int NOT NULL DEFAULT '1' COMMENT '多选时最多可选数',
  `deadline` bigint DEFAULT NULL COMMENT '截止时间(秒级时间戳)',
  `is_closed` tinyint NOT NULL DEFAULT '0' COMMENT '是否已关闭:0否 1是',
  `created_at` bigint DEFAULT NULL COMMENT '创建时间',
  `updated_at` bigint DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `forum_poll_topic_unique` (`topic_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS madong_portal.md_portal_forum_poll_option;
CREATE TABLE `md_portal_forum_poll_option` (
  `id` bigint NOT NULL COMMENT '雪花ID主键',
  `poll_id` bigint NOT NULL COMMENT '关联投票ID',
  `content` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '选项内容',
  `sort` int NOT NULL DEFAULT '0' COMMENT '排序',
  `vote_count` int NOT NULL DEFAULT '0' COMMENT '得票数',
  PRIMARY KEY (`id`),
  KEY `forum_poll_option_poll_index` (`poll_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS madong_portal.md_portal_forum_poll_vote;
CREATE TABLE `md_portal_forum_poll_vote` (
  `id` bigint NOT NULL COMMENT '雪花ID主键',
  `poll_id` bigint NOT NULL COMMENT '关联投票ID',
  `option_id` bigint NOT NULL COMMENT '关联选项ID',
  `member_id` bigint NOT NULL COMMENT '投票会员ID',
  `created_at` bigint DEFAULT NULL COMMENT '投票时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `forum_poll_vote_unique` (`poll_id`,`member_id`),
  KEY `forum_poll_vote_option_index` (`option_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS madong_portal.md_portal_forum_reply;
CREATE TABLE `md_portal_forum_reply` (
  `id` bigint NOT NULL COMMENT '雪花ID主键',
  `content` text COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '回答内容',
  `topic_id` bigint NOT NULL COMMENT '关联话题ID',
  `member_id` bigint NOT NULL COMMENT '回答用户ID',
  `like_count` int NOT NULL DEFAULT '0' COMMENT '点赞数',
  `dislike_count` int NOT NULL DEFAULT '0' COMMENT '反对数',
  `is_accepted` tinyint NOT NULL DEFAULT '0' COMMENT '是否被采纳',
  `status` tinyint NOT NULL DEFAULT '0' COMMENT '审核状态:0待审 1通过 2拒绝 3取消 4审批中',
  `deleted_at` bigint DEFAULT NULL COMMENT '删除时间',
  `created_at` bigint DEFAULT NULL COMMENT '创建时间',
  `updated_at` bigint DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `portal_ask_answer_question_id_index` (`topic_id`),
  KEY `portal_ask_answer_member_id_index` (`member_id`),
  KEY `portal_ask_answer_is_best_index` (`is_accepted`),
  KEY `portal_ask_answer_status_index` (`status`),
  KEY `portal_ask_answer_created_at_index` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS madong_portal.md_portal_forum_report;
CREATE TABLE `md_portal_forum_report` (
  `id` bigint NOT NULL COMMENT '主键ID',
  `member_id` bigint NOT NULL COMMENT '举报人ID',
  `target_type` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '目标类型: topic/reply/comment',
  `target_id` bigint NOT NULL COMMENT '目标ID',
  `reason` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '举报原因',
  `status` tinyint NOT NULL DEFAULT '1' COMMENT '状态: 1待处理 2已处理 3已驳回',
  `created_at` int DEFAULT NULL,
  `updated_at` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `portal_forum_report_member_id_index` (`member_id`),
  KEY `portal_forum_report_target_type_target_id_index` (`target_type`,`target_id`),
  KEY `portal_forum_report_status_index` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS madong_portal.md_portal_forum_sponsor;
CREATE TABLE `md_portal_forum_sponsor` (
  `id` bigint NOT NULL COMMENT '主键ID',
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '赞助商名称',
  `logo` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Logo图片地址',
  `url` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '赞助商链接',
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '简介',
  `sort` int NOT NULL DEFAULT '0' COMMENT '排序（越大越靠前）',
  `enabled` tinyint NOT NULL DEFAULT '1' COMMENT '是否启用: 1启用 0停用',
  `created_at` int DEFAULT NULL,
  `updated_at` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `portal_forum_sponsor_enabled_sort_index` (`enabled`,`sort`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS madong_portal.md_portal_forum_tag;
CREATE TABLE `md_portal_forum_tag` (
  `id` bigint NOT NULL COMMENT '雪花ID主键',
  `name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '标签名称',
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '标签描述',
  `enabled` tinyint NOT NULL DEFAULT '1' COMMENT '状态',
  `sort` int NOT NULL DEFAULT '0' COMMENT '排序',
  `usage_count` int NOT NULL DEFAULT '0' COMMENT '使用次数',
  `created_at` bigint DEFAULT NULL COMMENT '创建时间',
  `updated_at` bigint DEFAULT NULL COMMENT '更新时间',
  `deleted_at` bigint DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `forum_tag_name_unique` (`name`),
  KEY `portal_forum_tag_usage_count_index` (`usage_count`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS madong_portal.md_portal_forum_topic;
CREATE TABLE `md_portal_forum_topic` (
  `id` bigint NOT NULL COMMENT '雪花ID主键',
  `category_id` bigint DEFAULT NULL COMMENT '分类',
  `title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '话题标题',
  `content` longtext COLLATE utf8mb4_unicode_ci COMMENT '话题内容',
  `deleted_at` bigint DEFAULT NULL COMMENT '软删除标记',
  `created_at` bigint DEFAULT NULL COMMENT '创建时间',
  `updated_at` bigint DEFAULT NULL COMMENT '更新时间',
  `view_count` int NOT NULL DEFAULT '0' COMMENT '浏览量',
  `like_count` int NOT NULL DEFAULT '0' COMMENT '点赞数',
  `collect_count` int NOT NULL DEFAULT '0' COMMENT '收藏数',
  `comment_count` int NOT NULL DEFAULT '0' COMMENT '评论数',
  `member_id` bigint NOT NULL COMMENT '发帖用户ID',
  `is_sticky` tinyint NOT NULL DEFAULT '0' COMMENT '是否置顶',
  `sticky_order` int NOT NULL DEFAULT '0' COMMENT '置顶排序权重',
  `is_excellent` tinyint NOT NULL DEFAULT '0' COMMENT '是否精华',
  `is_accepted` tinyint NOT NULL DEFAULT '0' COMMENT '是否已采纳回复',
  `accepted_reply_id` bigint DEFAULT NULL COMMENT '被采纳回复ID',
  `status` tinyint NOT NULL DEFAULT '0' COMMENT '审核状态:0待审 1通过 2拒绝 3取消 4审批中',
  PRIMARY KEY (`id`),
  KEY `portal_forum_topic_member_id_index` (`member_id`),
  KEY `portal_forum_topic_created_at_index` (`created_at`),
  KEY `portal_forum_topic_view_count_index` (`view_count`),
  KEY `portal_forum_topic_status_index` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS madong_portal.md_portal_forum_topic_tag;
CREATE TABLE `md_portal_forum_topic_tag` (
  `topic_id` bigint NOT NULL COMMENT '话题ID',
  `tag_id` bigint NOT NULL COMMENT '标签ID',
  UNIQUE KEY `forum_topic_tag_unique` (`topic_id`,`tag_id`),
  KEY `portal_forum_topic_tag_topic_id_index` (`topic_id`),
  KEY `portal_forum_topic_tag_tag_id_index` (`tag_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 问答数据的前台可见性依赖审核存档，一并建表（结构同步自 madong_single）
DROP TABLE IF EXISTS madong_portal.md_sys_review_archive;
CREATE TABLE `md_sys_review_archive` (
  `id` bigint NOT NULL COMMENT '主键(沿用审核ID)',
  `reviewable_type` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '审核类型键',
  `reviewable_id` bigint DEFAULT NULL COMMENT '审核对象ID',
  `status` tinyint NOT NULL DEFAULT '0' COMMENT '审核状态:0待审 1通过 2拒绝 3取消 4审批中',
  `reason` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '审核意见',
  `reviewer_id` bigint DEFAULT NULL COMMENT '审核人ID',
  `reviewed_at` int DEFAULT NULL COMMENT '审核时间',
  `extra_data` json DEFAULT NULL COMMENT '业务快照(标题/内容/申请人等)',
  `flow_type` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'simple' COMMENT '审核模式:simple|workflow',
  `flow_instance_id` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '外部审批流实例ID',
  `cancel_reason` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '取消原因',
  `created_by` bigint DEFAULT NULL COMMENT '创建者',
  `updated_by` bigint DEFAULT NULL COMMENT '更新者',
  `created_at` bigint DEFAULT NULL COMMENT '创建时间',
  `updated_at` bigint DEFAULT NULL COMMENT '修改时间',
  `deleted_at` int unsigned DEFAULT NULL COMMENT '删除时间',
  `archived_at` int DEFAULT NULL COMMENT '归档时间',
  PRIMARY KEY (`id`),
  KEY `idx_reviewable` (`reviewable_type`,`reviewable_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- ============================================================================
-- 12. 文档数据（portal_book_project 系列 7 表，新版表名与旧版一致，剔 tenant_id）
-- ============================================================================
DROP TABLE IF EXISTS madong_portal.md_portal_book_project;
CREATE TABLE `md_portal_book_project` (
  `id` bigint NOT NULL COMMENT 'ID',
  `sort` int NOT NULL DEFAULT '0' COMMENT '权重',
  `desc` longtext COLLATE utf8mb4_unicode_ci COMMENT '描述',
  `read` int DEFAULT '0' COMMENT '阅读量',
  `code` varchar(60) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '唯一标识',
  `title` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '项目名称',
  `thumb` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '缩略图',
  `enabled` tinyint DEFAULT '1' COMMENT '状态:0=禁用,1=启用',
  `is_index` tinyint DEFAULT '1' COMMENT '是否显示列表',
  `auth_type` tinyint DEFAULT '0' COMMENT '权限类型',
  `created_by` bigint DEFAULT NULL COMMENT '创建人ID',
  `created_at` bigint DEFAULT NULL,
  `updated_at` bigint DEFAULT NULL,
  `deleted_at` bigint DEFAULT NULL,
  `secret_key` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '秘钥',
  PRIMARY KEY (`id`),
  UNIQUE KEY `book_project_code_unique` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
DROP TABLE IF EXISTS madong_portal.md_portal_book_project_auth_access;
CREATE TABLE `md_portal_book_project_auth_access` (
  `project_id` bigint NOT NULL COMMENT '知识库ID',
  `admin_id` bigint NOT NULL COMMENT '用户ID'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
DROP TABLE IF EXISTS madong_portal.md_portal_book_project_auth_role_access;
CREATE TABLE `md_portal_book_project_auth_role_access` (
  `project_id` bigint NOT NULL COMMENT '知识库ID',
  `role_id` bigint NOT NULL COMMENT '角色ID'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
DROP TABLE IF EXISTS madong_portal.md_portal_book_project_auth_tags_access;
CREATE TABLE `md_portal_book_project_auth_tags_access` (
  `project_id` bigint NOT NULL COMMENT '知识库ID',
  `tag_id` bigint NOT NULL COMMENT '用户标签ID'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- ============================================================================
-- 14. 应用市场（md_portal_app 系列 10 表；favorite 为新版独有表，建空表）
-- ============================================================================
DROP TABLE IF EXISTS madong_portal.`md_portal_app`;
CREATE TABLE `md_portal_app` (
  `id` bigint NOT NULL COMMENT '应用唯一标识',
  `code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '应用标识',
  `name` varchar(128) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '应用名称',
  `description` text COLLATE utf8mb4_unicode_ci COMMENT '应用描述（富文本）',
  `developer` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '开发者/商家名称',
  `category_id` bigint NOT NULL COMMENT '所属分类ID',
  `thumb` varchar(256) COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '封面图链接',
  `download_url` varchar(256) COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '下载链接',
  `source` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'local' COMMENT '附件来源：local/gitcode/github/gitee',
  `is_free` tinyint NOT NULL DEFAULT '0' COMMENT '是否免费（1=免费，0=付费）',
  `points_price` int DEFAULT NULL COMMENT '积分价格（仅付费时有效）',
  `currency_price` decimal(10,2) DEFAULT NULL COMMENT '人民币价格',
  `sort_weight` int NOT NULL DEFAULT '0' COMMENT '排序权重',
  `download_count` int NOT NULL DEFAULT '0' COMMENT '累计下载量',
  `favorite_count` int NOT NULL DEFAULT '0' COMMENT '收藏量',
  `status` tinyint NOT NULL DEFAULT '0' COMMENT '是否上架',
  `created_at` bigint DEFAULT NULL COMMENT '创建时间',
  `updated_at` bigint DEFAULT NULL COMMENT '更新时间',
  `version` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '1.0.0' COMMENT '当前最新版本',
  `readme_content` text COLLATE utf8mb4_unicode_ci COMMENT 'Readme内容',
  `member_id` bigint DEFAULT NULL COMMENT '用户',
  `deleted_at` bigint DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`),
  KEY `portal_app_category_id_index` (`category_id`),
  KEY `portal_app_is_free_index` (`is_free`),
  KEY `portal_app_sort_weight_index` (`sort_weight`),
  KEY `portal_app_download_count_index` (`download_count`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
DROP TABLE IF EXISTS madong_portal.`md_portal_app_carousel`;
CREATE TABLE `md_portal_app_carousel` (
  `id` bigint NOT NULL,
  `app_id` bigint NOT NULL COMMENT '关联应用ID',
  `image_url` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '轮播图URL',
  `link_url` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '点击跳转链接',
  `sort_weight` int NOT NULL DEFAULT '0' COMMENT '排序权重',
  PRIMARY KEY (`id`),
  KEY `portal_app_carousel_app_id_sort_weight_index` (`app_id`,`sort_weight`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
DROP TABLE IF EXISTS madong_portal.`md_portal_app_category`;
CREATE TABLE `md_portal_app_category` (
  `id` bigint NOT NULL COMMENT '分类唯一标识',
  `parent_id` bigint NOT NULL DEFAULT '0' COMMENT '父分类ID',
  `name` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '分类名称',
  `code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '分类标识',
  `sort` int NOT NULL DEFAULT '0' COMMENT '分类排序',
  `enabled` tinyint NOT NULL DEFAULT '1' COMMENT '是否启用',
  `deleted_at` bigint DEFAULT NULL COMMENT '删除时间',
  `created_at` bigint NOT NULL DEFAULT '0' COMMENT '创建时间',
  `updated_at` bigint NOT NULL DEFAULT '0' COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `portal_app_category_name_unique` (`name`),
  KEY `portal_app_category_parent_id_index` (`parent_id`),
  KEY `portal_app_category_sort_index` (`sort`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
DROP TABLE IF EXISTS madong_portal.`md_portal_app_comment`;
CREATE TABLE `md_portal_app_comment` (
  `id` bigint NOT NULL COMMENT '主键ID',
  `app_id` bigint NOT NULL COMMENT '关联应用ID',
  `user_id` bigint NOT NULL COMMENT '评论用户ID',
  `parent_id` bigint NOT NULL DEFAULT '0' COMMENT '父评论ID',
  `content` text COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '评论内容',
  `rating` tinyint NOT NULL DEFAULT '0' COMMENT '评分（1-5星）',
  `status` tinyint NOT NULL DEFAULT '0' COMMENT '状态（0=待审核，1=已发布，2=已删除）',
  `reply_to_user_id` bigint DEFAULT NULL COMMENT '回复目标用户ID',
  `created_at` bigint DEFAULT NULL COMMENT '评论时间',
  `updated_at` bigint DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `portal_app_comment_app_id_status_created_at_index` (`app_id`,`status`,`created_at`),
  KEY `portal_app_comment_parent_id_index` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
DROP TABLE IF EXISTS madong_portal.`md_portal_app_exchange_config`;
CREATE TABLE `md_portal_app_exchange_config` (
  `id` bigint NOT NULL COMMENT '配置唯一标识',
  `points_per_currency` int NOT NULL DEFAULT '100' COMMENT '1元可兑换积分数量',
  `min_exchange_points` int NOT NULL DEFAULT '100' COMMENT '兑换最小积分',
  `deleted_at` bigint DEFAULT NULL COMMENT '删除时间',
  `created_at` bigint NOT NULL DEFAULT '0' COMMENT '创建时间',
  `updated_at` bigint NOT NULL DEFAULT '0' COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `exchange_config_unique` (`points_per_currency`,`min_exchange_points`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
DROP TABLE IF EXISTS madong_portal.`md_portal_app_favorite`;
CREATE TABLE `md_portal_app_favorite` (
  `id` bigint NOT NULL COMMENT '主键ID',
  `member_id` bigint NOT NULL COMMENT '会员ID',
  `app_id` bigint NOT NULL COMMENT '应用ID',
  `created_at` bigint DEFAULT NULL COMMENT '收藏时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `app_favorite_unique` (`member_id`,`app_id`),
  KEY `portal_app_favorite_member_id_index` (`member_id`),
  KEY `portal_app_favorite_app_id_index` (`app_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- ============================================================================
-- 16. 友情链接（md_web_link 1 表，结构一致剔 tenant_id）
-- ============================================================================
DROP TABLE IF EXISTS madong_portal.`md_web_link`;
CREATE TABLE `md_web_link` (
  `id` bigint NOT NULL COMMENT '主键',
  `name` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '链接名称',
  `url` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '链接地址',
  `logo` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '链接 logo',
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '链接描述',
  `category` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'footer' COMMENT '链接分类',
  `target` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '_blank' COMMENT '打开方式',
  `enabled` tinyint NOT NULL DEFAULT '1' COMMENT '状态: 1正常 0停用',
  `sort` smallint NOT NULL DEFAULT '0' COMMENT '排序',
  `click_count` int NOT NULL DEFAULT '0' COMMENT '点击次数',
  `created_at` bigint DEFAULT NULL COMMENT '创建时间',
  `updated_at` bigint DEFAULT NULL COMMENT '修改时间',
  `deleted_at` bigint DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS madong_portal.`md_portal_app_tag`;
CREATE TABLE `md_portal_app_tag` (
  `id` bigint NOT NULL COMMENT '标签唯一标识',
  `name` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '标签名称',
  `sort` int NOT NULL DEFAULT '1' COMMENT '排序',
  `deleted_at` bigint DEFAULT NULL COMMENT '删除时间',
  `created_at` bigint DEFAULT NULL COMMENT '创建时间',
  `updated_at` bigint DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `portal_app_tag_name_unique` (`name`),
  KEY `portal_app_tag_deleted_at_index` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
DROP TABLE IF EXISTS madong_portal.`md_portal_app_tag_relation`;
CREATE TABLE `md_portal_app_tag_relation` (
  `app_id` bigint NOT NULL COMMENT '应用ID',
  `tag_id` bigint NOT NULL COMMENT '标签ID',
  PRIMARY KEY (`app_id`,`tag_id`),
  KEY `portal_app_tag_relation_app_id_index` (`app_id`),
  KEY `portal_app_tag_relation_tag_id_index` (`tag_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
DROP TABLE IF EXISTS madong_portal.`md_portal_app_transaction`;
CREATE TABLE `md_portal_app_transaction` (
  `id` bigint NOT NULL COMMENT '交易唯一标识',
  `member_id` bigint NOT NULL COMMENT '用户ID',
  `app_id` bigint NOT NULL COMMENT '应用ID',
  `type` tinyint NOT NULL COMMENT '交易类型（1=积分兑换，2=人民币购买）',
  `amount` decimal(10,2) DEFAULT NULL COMMENT '支付金额',
  `points_used` int DEFAULT NULL COMMENT '使用积分数量',
  `currency_paid` decimal(10,2) DEFAULT NULL COMMENT '实际支付金额',
  `transaction_no` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '第三方支付单号',
  `status` tinyint NOT NULL DEFAULT '3' COMMENT '交易状态（1=成功，2=失败，3=支付中）',
  `created_at` bigint NOT NULL DEFAULT '0' COMMENT '交易时间',
  `updated_at` bigint DEFAULT NULL COMMENT '更新时间',
  `completed_at` bigint DEFAULT NULL COMMENT '交易完成时间',
  PRIMARY KEY (`id`),
  KEY `portal_app_transaction_member_id_index` (`member_id`),
  KEY `portal_app_transaction_app_id_index` (`app_id`),
  KEY `portal_app_transaction_status_index` (`status`),
  KEY `portal_app_transaction_created_at_index` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
DROP TABLE IF EXISTS madong_portal.`md_portal_app_versions`;
CREATE TABLE `md_portal_app_versions` (
  `id` bigint NOT NULL,
  `app_id` bigint NOT NULL COMMENT '关联应用ID',
  `version` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '版本号',
  `release_notes` text COLLATE utf8mb4_unicode_ci COMMENT '更新日志',
  `download_url` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '版本下载链接',
  `source` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'local' COMMENT '附件来源：local/gitcode/github/gitee',
  `repo_url` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '仓库地址（仓库来源时）',
  `repo_tag` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '仓库Release标签（独立于版本号）',
  `release_time` bigint DEFAULT NULL COMMENT '发布时间',
  `sort_weight` int NOT NULL DEFAULT '0' COMMENT '排序权重',
  PRIMARY KEY (`id`),
  UNIQUE KEY `portal_app_versions_app_id_version_unique` (`app_id`,`version`),
  KEY `portal_app_versions_app_id_index` (`app_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS madong_portal.md_portal_book_project_page;
CREATE TABLE `md_portal_book_project_page` (
  `id` bigint NOT NULL,
  `pid` bigint NOT NULL DEFAULT '0' COMMENT '父ID',
  `project_id` bigint NOT NULL DEFAULT '0' COMMENT '归属项目',
  `type` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '类型:1=章节,2=文档,3=外部地址',
  `title` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '标题',
  `desc` longtext COLLATE utf8mb4_unicode_ci COMMENT '摘要',
  `enabled` tinyint NOT NULL DEFAULT '1' COMMENT '状态',
  `link` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '跳转地址',
  `content` longtext COLLATE utf8mb4_unicode_ci COMMENT '内容',
  `md_content` longtext COLLATE utf8mb4_unicode_ci COMMENT 'markdown内容',
  `read` int DEFAULT '0' COMMENT '阅读量',
  `is_auth` tinyint DEFAULT '1' COMMENT '权限控制',
  `sort` int NOT NULL DEFAULT '0' COMMENT '权重',
  `admin_id` bigint DEFAULT NULL COMMENT '作者',
  `created_at` bigint DEFAULT NULL,
  `updated_at` bigint DEFAULT NULL,
  `deleted_at` bigint DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
DROP TABLE IF EXISTS madong_portal.md_portal_book_project_page_comment;
CREATE TABLE `md_portal_book_project_page_comment` (
  `id` bigint NOT NULL,
  `pid` bigint NOT NULL DEFAULT '0',
  `project_page_id` bigint DEFAULT NULL,
  `content` text COLLATE utf8mb4_unicode_ci,
  `like_count` bigint DEFAULT NULL,
  `state` tinyint NOT NULL DEFAULT '3',
  `depth` tinyint NOT NULL DEFAULT '1',
  `root_id` bigint DEFAULT NULL,
  `created_at` bigint DEFAULT NULL,
  `updated_at` bigint DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
DROP TABLE IF EXISTS madong_portal.md_portal_book_project_page_corrections;
CREATE TABLE `md_portal_book_project_page_corrections` (
  `id` bigint NOT NULL,
  `project_page_id` bigint NOT NULL COMMENT '关联文档ID',
  `original_content` longtext COLLATE utf8mb4_unicode_ci,
  `corrected_content` longtext COLLATE utf8mb4_unicode_ci,
  `submitted_by` bigint DEFAULT NULL,
  `submitted_at` int DEFAULT NULL,
  `status` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `reviewed_by` bigint DEFAULT NULL,
  `reviewed_at` bigint DEFAULT NULL,
  `deleted_at` bigint DEFAULT NULL,
  `reason` longtext COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- B. 会员数据迁移（第一步：用户/等级/标签/积分流水/签到）
--    显式列清单，剔除 tenant_id，ID 原样保留
-- ============================================================================

START TRANSACTION;

-- 1. 用户基础数据 (md_member 221 行)
INSERT INTO madong_portal.md_member
    (id, username, email, phone, password, nickname, avatar, level_id, points, balance,
     gender, birthday, last_login_time, last_login_ip, login_count, enabled,
     created_at, updated_at, deleted_at, bio)
SELECT id, username, email, phone, password, nickname, avatar, level_id, points, balance,
       gender, birthday, last_login_time, last_login_ip, login_count, enabled,
       created_at, updated_at, deleted_at, bio
FROM madong_saas_portal.md_member;

-- 2. 会员等级 (md_member_level，源为空表，保持幂等结构迁移)
INSERT INTO madong_portal.md_member_level
    (id, name, level, min_points, max_points, discount, icon, color, description, enabled,
     created_at, updated_at)
SELECT id, name, level, min_points, max_points, discount, icon, color, description, enabled,
       created_at, updated_at
FROM madong_saas_portal.md_member_level;

-- 3. 用户标签 (md_member_tag 2 行)
INSERT INTO madong_portal.md_member_tag
    (id, name, color, description, sort, enabled, created_at, updated_at)
SELECT id, name, color, description, sort, enabled, created_at, updated_at
FROM madong_saas_portal.md_member_tag;

-- 4. 会员标签关系 (md_member_tag_relation，源为空表)
INSERT INTO madong_portal.md_member_tag_relation (member_id, tag_id)
SELECT member_id, tag_id
FROM madong_saas_portal.md_member_tag_relation;

-- 5. 会员积分流水 (md_member_points 17 行，过滤 1 条孤儿引用，预期 16 行)
INSERT INTO madong_portal.md_member_points
    (id, member_id, points, balance, type, source, remark, operator, order_id,
     created_at, updated_at)
SELECT p.id, p.member_id, p.points, p.balance, p.type, p.source, p.remark, p.operator, p.order_id,
       p.created_at, p.updated_at
FROM madong_saas_portal.md_member_points p
WHERE EXISTS (SELECT 1 FROM madong_saas_portal.md_member m WHERE m.id = p.member_id);

-- 6. 会员签到 (md_member_sign 17 行，过滤 1 条孤儿引用，预期 16 行)
INSERT INTO madong_portal.md_member_sign
    (id, member_id, sign_date, points, continuous_days, created_at, updated_at,
     device_ip, device_ua)
SELECT s.id, s.member_id, s.sign_date, s.points, s.continuous_days, s.created_at, s.updated_at,
       s.device_ip, s.device_ua
FROM madong_saas_portal.md_member_sign s
WHERE EXISTS (SELECT 1 FROM madong_saas_portal.md_member m WHERE m.id = s.member_id);

-- ============================================================================
-- C. 门户问答数据迁移（第二步：md_portal_ask_* → md_portal_forum_*）
--    字段映射依据：plugin/portal/.../2026_09_18_000002_rename_portal_ask_to_forum.php
-- ============================================================================

-- 1. 分类 (4 行)：enabled → status；源无 deleted_at 补 NULL
INSERT INTO madong_portal.md_portal_forum_category
    (id, name, slug, description, parent_id, sort, status, created_at, updated_at, deleted_at)
SELECT id, name, slug, description, IFNULL(parent_id, 0), sort, IFNULL(enabled, 1),
       created_at, updated_at, NULL
FROM madong_saas_portal.md_portal_ask_category;

-- 2. 问题 → 话题 (7 行)：is_solved → is_accepted；solved_answer_id → accepted_reply_id；
--    status varchar('0'/'1') → tinyint
INSERT INTO madong_portal.md_portal_forum_topic
    (id, category_id, title, content, deleted_at, created_at, updated_at,
     view_count, like_count, collect_count, comment_count, member_id,
     is_sticky, sticky_order, is_excellent, is_accepted, accepted_reply_id, status)
SELECT id, category_id, title, content, deleted_at, created_at, updated_at,
       IFNULL(view_count, 0), IFNULL(like_count, 0), IFNULL(collect_count, 0), IFNULL(comment_count, 0),
       member_id, IFNULL(is_sticky, 0), IFNULL(sticky_order, 0), IFNULL(is_excellent, 0),
       IFNULL(is_solved, 0), solved_answer_id, CAST(IFNULL(status, '0') AS SIGNED)
FROM madong_saas_portal.md_portal_ask_question;

-- 3. 回答 → 回复 (10 行)：question_id → topic_id；is_best → is_accepted
INSERT INTO madong_portal.md_portal_forum_reply
    (id, content, topic_id, member_id, like_count, dislike_count, is_accepted, status,
     deleted_at, created_at, updated_at)
SELECT id, content, question_id, member_id, IFNULL(like_count, 0), IFNULL(dislike_count, 0),
       IFNULL(is_best, 0), IFNULL(status, 0), deleted_at, created_at, updated_at
FROM madong_saas_portal.md_portal_ask_answer;

-- 4. 标签 (6 行)：源无 deleted_at 补 NULL
INSERT INTO madong_portal.md_portal_forum_tag
    (id, name, description, enabled, sort, usage_count, created_at, updated_at, deleted_at)
SELECT id, name, description, IFNULL(enabled, 1), IFNULL(sort, 0), IFNULL(usage_count, 0),
       created_at, updated_at, NULL
FROM madong_saas_portal.md_portal_ask_tag;

-- 5. 问题标签关联 (17 行)：question_id → topic_id
INSERT INTO madong_portal.md_portal_forum_topic_tag (topic_id, tag_id)
SELECT question_id, tag_id
FROM madong_saas_portal.md_portal_ask_question_tag;

-- 6. 收藏 (1 行)：question_id → topic_id
INSERT INTO madong_portal.md_portal_forum_collection (member_id, topic_id, created_at)
SELECT member_id, question_id, created_at
FROM madong_saas_portal.md_portal_ask_collection;

-- 7. 点赞 (6 行，过滤孤儿引用后预期 5 行)：
--    question → topic、answer → reply；仅保留 target 仍存在的记录
INSERT INTO madong_portal.md_portal_forum_like
    (id, member_id, target_type, target_id, created_at, updated_at)
SELECT l.id, l.member_id,
       CASE l.target_type WHEN 'question' THEN 'topic' WHEN 'answer' THEN 'reply' ELSE l.target_type END,
       l.target_id, l.created_at, l.updated_at
FROM madong_saas_portal.md_portal_ask_like l
WHERE (l.target_type = 'question' AND EXISTS (SELECT 1 FROM madong_saas_portal.md_portal_ask_question q WHERE q.id = l.target_id))
   OR (l.target_type = 'answer'   AND EXISTS (SELECT 1 FROM madong_saas_portal.md_portal_ask_answer   a WHERE a.id = l.target_id))
   OR (l.target_type = 'comment'  AND EXISTS (SELECT 1 FROM madong_saas_portal.md_portal_ask_comment  c WHERE c.id = l.target_id));

-- 8. 反对 (0 行，同点赞规则，保持幂等结构迁移)
INSERT INTO madong_portal.md_portal_forum_dislike
    (id, member_id, target_type, target_id, created_at, updated_at)
SELECT d.id, d.member_id,
       CASE d.target_type WHEN 'question' THEN 'topic' WHEN 'answer' THEN 'reply' ELSE d.target_type END,
       d.target_id, d.created_at, d.updated_at
FROM madong_saas_portal.md_portal_ask_dislike d
WHERE (d.target_type = 'question' AND EXISTS (SELECT 1 FROM madong_saas_portal.md_portal_ask_question q WHERE q.id = d.target_id))
   OR (d.target_type = 'answer'   AND EXISTS (SELECT 1 FROM madong_saas_portal.md_portal_ask_answer   a WHERE a.id = d.target_id))
   OR (d.target_type = 'comment'  AND EXISTS (SELECT 1 FROM madong_saas_portal.md_portal_ask_comment  c WHERE c.id = d.target_id));

-- 9. 评论 (7 行)：parent_type question → topic、answer → reply
INSERT INTO madong_portal.md_portal_forum_comment
    (id, content, parent_type, parent_id, member_id, status, reply_to, deleted_at,
     created_at, updated_at)
SELECT id, content,
       CASE parent_type WHEN 'question' THEN 'topic' WHEN 'answer' THEN 'reply' ELSE parent_type END,
       parent_id, member_id, IFNULL(status, 0), IFNULL(reply_to, 0), deleted_at,
       created_at, updated_at
FROM madong_saas_portal.md_portal_ask_comment;

-- 10. 积分类型 (4 行)：结构一致，直接迁移
INSERT INTO madong_portal.md_portal_forum_integral_type
    (id, type_code, type_name, change_direction, default_value, daily_limit,
     related_entity_type, description)
SELECT id, type_code, type_name, change_direction, default_value, daily_limit,
       related_entity_type, description
FROM madong_saas_portal.md_portal_ask_integral_type;

-- 11. 审核存档 (20 行)：前台列表 approvedArchive() 只显示 sys_review_archive
--     中 status=APPROVED 的内容，问答数据必须带审核存档否则前台空白。
--     reviewable_type 转换：question→topic、answer→reply、comment 不变。
--     注：源库 comment 归档 3 条中 2 条指向不存在的评论（源库脏数据），INSERT 原样保留。
INSERT IGNORE INTO madong_portal.md_sys_review_archive
    (id, reviewable_type, reviewable_id, status, reason, reviewer_id, reviewed_at,
     extra_data, flow_type, flow_instance_id, cancel_reason, created_by, updated_by,
     created_at, updated_at, deleted_at, archived_at)
SELECT id,
       CASE reviewable_type WHEN 'question' THEN 'topic' WHEN 'answer' THEN 'reply' ELSE reviewable_type END,
       reviewable_id, status, reason, reviewer_id, reviewed_at, extra_data, flow_type,
       flow_instance_id, cancel_reason, created_by, updated_by, created_at, updated_at,
       deleted_at, archived_at
FROM madong_saas_portal.md_sys_review_archive
WHERE reviewable_type IN ('question', 'answer', 'comment');
-- 13. 文档数据迁移：project 10 行 / page 453 行 / auth_tags_access 5 行，
--     其余 4 张关联表源库为空；INSERT IGNORE 幂等
INSERT IGNORE INTO madong_portal.md_portal_book_project (
    `id`,`sort`,`desc`,`read`,`code`,`title`,`thumb`,`enabled`,`is_index`,`auth_type`,`created_by`,`created_at`,`updated_at`,`deleted_at`,`secret_key`
) SELECT 
    `id`,`sort`,`desc`,`read`,`code`,`title`,`thumb`,`enabled`,`is_index`,`auth_type`,`created_by`,`created_at`,`updated_at`,`deleted_at`,`secret_key`
FROM madong_saas_portal.md_portal_book_project;
INSERT IGNORE INTO madong_portal.md_portal_book_project_auth_access (
    `project_id`,`admin_id`
) SELECT 
    `project_id`,`admin_id`
FROM madong_saas_portal.md_portal_book_project_auth_access;
INSERT IGNORE INTO madong_portal.md_portal_book_project_auth_role_access (
    `project_id`,`role_id`
) SELECT 
    `project_id`,`role_id`
FROM madong_saas_portal.md_portal_book_project_auth_role_access;
INSERT IGNORE INTO madong_portal.md_portal_book_project_auth_tags_access (
    `project_id`,`tag_id`
) SELECT 
    `project_id`,`tag_id`
FROM madong_saas_portal.md_portal_book_project_auth_tags_access;
INSERT IGNORE INTO madong_portal.md_portal_book_project_page (
    `id`,`pid`,`project_id`,`type`,`title`,`desc`,`enabled`,`link`,`content`,`md_content`,`read`,`is_auth`,`sort`,`admin_id`,`created_at`,`updated_at`,`deleted_at`
) SELECT 
    `id`,`pid`,`project_id`,`type`,`title`,`desc`,`enabled`,`link`,`content`,`md_content`,`read`,`is_auth`,`sort`,`admin_id`,`created_at`,`updated_at`,`deleted_at`
FROM madong_saas_portal.md_portal_book_project_page;
INSERT IGNORE INTO madong_portal.md_portal_book_project_page_comment (
    `id`,`pid`,`project_page_id`,`content`,`like_count`,`state`,`depth`,`root_id`,`created_at`,`updated_at`
) SELECT 
    `id`,`pid`,`project_page_id`,`content`,`like_count`,`state`,`depth`,`root_id`,`created_at`,`updated_at`
FROM madong_saas_portal.md_portal_book_project_page_comment;
INSERT IGNORE INTO madong_portal.md_portal_book_project_page_corrections (
    `id`,`project_page_id`,`original_content`,`corrected_content`,`submitted_by`,`submitted_at`,`status`,`reviewed_by`,`reviewed_at`,`deleted_at`,`reason`
) SELECT 
    `id`,`project_page_id`,`original_content`,`corrected_content`,`submitted_by`,`submitted_at`,`status`,`reviewed_by`,`reviewed_at`,`deleted_at`,`reason`
FROM madong_saas_portal.md_portal_book_project_page_corrections;
-- 15. 应用市场数据迁移：app 4 / carousel 8（过滤 1 条源库孤儿）/ category 2（code 为新版必填列按 id 映射）/ tag 8 / versions 5（新增仓库字段补默认值）/ transaction 3（其中 1 条源库即会员孤儿，忠实保留），comment/tag_relation/exchange_config 源库为空
INSERT IGNORE INTO madong_portal.md_portal_app
  (id, code, name, description, developer, category_id, thumb, download_url, source,
   is_free, points_price, currency_price, sort_weight, download_count, favorite_count,
   status, created_at, updated_at, version, readme_content, member_id, deleted_at)
SELECT id, code, name, description, developer, category_id, thumb, download_url, 'local',
   is_free, points_price, currency_price, sort_weight, download_count, favorite_count,
   status, created_at, updated_at, version, readme_content, member_id, NULL
FROM madong_saas_portal.md_portal_app;
INSERT IGNORE INTO madong_portal.md_portal_app_carousel
  (id, app_id, image_url, link_url, sort_weight)
SELECT c.id, c.app_id, c.image_url, c.link_url, c.sort_weight
FROM madong_saas_portal.md_portal_app_carousel c
JOIN madong_saas_portal.md_portal_app a ON c.app_id = a.id;
INSERT IGNORE INTO madong_portal.md_portal_app_category
  (id, parent_id, name, code, sort, enabled, deleted_at, created_at, updated_at)
SELECT id, parent_id, name,
       CASE id WHEN 230079316091207680 THEN 'php-standalone' WHEN 230079316095401984 THEN 'php-saas' ELSE CONCAT('cat-', id) END,
       sort, 1, deleted_at, created_at, updated_at
FROM madong_saas_portal.md_portal_app_category;
INSERT IGNORE INTO madong_portal.md_portal_app_comment
  (id, app_id, user_id, parent_id, content, rating, status, reply_to_user_id, created_at, updated_at)
SELECT id, app_id, user_id, parent_id, content, rating, status, reply_to_user_id, created_at, updated_at
FROM madong_saas_portal.md_portal_app_comment;
INSERT IGNORE INTO madong_portal.md_portal_app_exchange_config
  (id, points_per_currency, min_exchange_points, deleted_at, created_at, updated_at)
SELECT id, points_per_currency, min_exchange_points, deleted_at, created_at, updated_at
FROM madong_saas_portal.md_portal_app_exchange_config;
INSERT IGNORE INTO madong_portal.md_portal_app_tag
  (id, name, sort, deleted_at, created_at, updated_at)
SELECT id, name, sort, deleted_at, created_at, updated_at
FROM madong_saas_portal.md_portal_app_tag;
INSERT IGNORE INTO madong_portal.md_portal_app_tag_relation (app_id, tag_id)
SELECT app_id, tag_id FROM madong_saas_portal.md_portal_app_tag_relation;
INSERT IGNORE INTO madong_portal.md_portal_app_transaction
  (id, member_id, app_id, type, amount, points_used, currency_paid, transaction_no, status, created_at, updated_at, completed_at)
SELECT id, member_id, app_id, type, amount, points_used, currency_paid, transaction_no, status, created_at, updated_at, completed_at
FROM madong_saas_portal.md_portal_app_transaction;
INSERT IGNORE INTO madong_portal.md_portal_app_versions
  (id, app_id, version, release_notes, download_url, source, repo_url, repo_tag, release_time, sort_weight)
SELECT id, app_id, version, release_notes, download_url, 'local', '', '', release_time, sort_weight
FROM madong_saas_portal.md_portal_app_versions;
-- 17. 友情链接迁移：2 行（workerman / mldong，均 footer 分类启用），ID 原样保留
INSERT IGNORE INTO madong_portal.md_web_link
  (id, name, url, logo, description, category, target, enabled, sort, click_count, created_at, updated_at, deleted_at)
SELECT id, name, url, logo, description, category, target, enabled, sort, click_count, created_at, updated_at, deleted_at
FROM madong_saas_portal.md_web_link;

-- ============================================================================
-- 18. 系统设置（md_sys_config 1 表；独立版无 tenant_id/template_id 列）
-- ============================================================================
DROP TABLE IF EXISTS madong_portal.`md_sys_config`;
CREATE TABLE `md_sys_config` (
  `id` bigint NOT NULL COMMENT '配置ID',
  `source` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'template' COMMENT '配置来源: template-模板同步 manual-手动添加',
  `group_code` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '分组编码',
  `code` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '唯一编码',
  `name` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '配置名称',
  `content` longtext COLLATE utf8mb4_unicode_ci COMMENT '配置内容',
  `is_sys` tinyint NOT NULL DEFAULT '0' COMMENT '是否系统',
  `enabled` tinyint NOT NULL DEFAULT '1' COMMENT '是否启用',
  `sort` int NOT NULL DEFAULT '0' COMMENT '排序',
  `created_at` bigint DEFAULT NULL COMMENT '创建时间',
  `created_by` bigint DEFAULT NULL COMMENT '创建用户',
  `updated_at` bigint DEFAULT NULL COMMENT '更新时间',
  `updated_by` bigint DEFAULT NULL COMMENT '更新用户',
  `deleted_at` bigint DEFAULT NULL COMMENT '是否删除',
  `remark` longtext COLLATE utf8mb4_unicode_ci COMMENT '备注',
  PRIMARY KEY (`id`),
  KEY `sys_config_code_index` (`code`),
  KEY `sys_config_group_code_index` (`group_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 19. 系统设置-备案信息迁移：site_setting 1 行（ICP 备案号/公网安备/版权），
--     ID 沿用源库；logo 置空（SaaS 上传路径独立版不存在，避免 404）
--     独立版读取仅按 code 查询（ConfigService::config），enabled 不影响生效
INSERT IGNORE INTO madong_portal.md_sys_config
  (id, source, group_code, code, name, content, is_sys, enabled, sort, created_at, created_by, updated_at, updated_by, deleted_at, remark)
SELECT id, source, group_code, code, name,
       '{"site_open":1,"site_name":"Madong 社区","site_logo":"","site_network_security":"闽公网安备35021302000739号","site_keywords":"madong,madong快速框架,madong极速框架","site_record_no":"闽ICP备2024042441号-2","site_icp_url":"https://beian.miit.gov.cn/","site_network_security_url":"https://beian.miit.gov.cn/","site_copyright":" Copyright © 2021-2026 madong.tech All Rights Reserved."}',
       is_sys, 1, sort, created_at, created_by, UNIX_TIMESTAMP(), updated_by, deleted_at, remark
FROM madong_saas_portal.md_sys_config
WHERE code = 'site_setting' AND group_code = 'default';

COMMIT;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================================
-- D. 迁移验证（脚本内快速自检：行数 + 关联完整性）
-- ============================================================================

-- D1. 各表行数
SELECT 'member' AS tbl, COUNT(*) AS rows_in_target FROM madong_portal.md_member
UNION ALL SELECT 'member_level',       COUNT(*) FROM madong_portal.md_member_level
UNION ALL SELECT 'member_tag',         COUNT(*) FROM madong_portal.md_member_tag
UNION ALL SELECT 'member_tag_relation',COUNT(*) FROM madong_portal.md_member_tag_relation
UNION ALL SELECT 'member_points',      COUNT(*) FROM madong_portal.md_member_points
UNION ALL SELECT 'member_sign',        COUNT(*) FROM madong_portal.md_member_sign
UNION ALL SELECT 'forum_category',     COUNT(*) FROM madong_portal.md_portal_forum_category
UNION ALL SELECT 'forum_topic',        COUNT(*) FROM madong_portal.md_portal_forum_topic
UNION ALL SELECT 'forum_reply',        COUNT(*) FROM madong_portal.md_portal_forum_reply
UNION ALL SELECT 'forum_tag',          COUNT(*) FROM madong_portal.md_portal_forum_tag
UNION ALL SELECT 'forum_topic_tag',    COUNT(*) FROM madong_portal.md_portal_forum_topic_tag
UNION ALL SELECT 'forum_collection',   COUNT(*) FROM madong_portal.md_portal_forum_collection
UNION ALL SELECT 'forum_like',         COUNT(*) FROM madong_portal.md_portal_forum_like
UNION ALL SELECT 'forum_dislike',      COUNT(*) FROM madong_portal.md_portal_forum_dislike
UNION ALL SELECT 'forum_comment',      COUNT(*) FROM madong_portal.md_portal_forum_comment
UNION ALL SELECT 'forum_integral_type',COUNT(*) FROM madong_portal.md_portal_forum_integral_type;

-- D2. 关联完整性（期望全部为 0）
SELECT 'topic.member_id 孤儿'   AS check_item, COUNT(*) AS orphans FROM madong_portal.md_portal_forum_topic  t LEFT JOIN madong_portal.md_member m ON t.member_id = m.id WHERE m.id IS NULL
UNION ALL SELECT 'reply.topic_id 孤儿',     COUNT(*) FROM madong_portal.md_portal_forum_reply  r LEFT JOIN madong_portal.md_portal_forum_topic t ON r.topic_id  = t.id WHERE t.id IS NULL
UNION ALL SELECT 'reply.member_id 孤儿',    COUNT(*) FROM madong_portal.md_portal_forum_reply  r LEFT JOIN madong_portal.md_member m ON r.member_id = m.id WHERE m.id IS NULL
UNION ALL SELECT 'like.reply 孤儿',         COUNT(*) FROM madong_portal.md_portal_forum_like   l LEFT JOIN madong_portal.md_portal_forum_reply r ON l.target_id = r.id WHERE l.target_type='reply'   AND r.id IS NULL
UNION ALL SELECT 'comment.parent 孤儿',     COUNT(*) FROM madong_portal.md_portal_forum_comment c LEFT JOIN madong_portal.md_portal_forum_reply  r ON c.parent_id = r.id AND c.parent_type='reply' LEFT JOIN madong_portal.md_portal_forum_topic t ON c.parent_id = t.id AND c.parent_type='topic' WHERE r.id IS NULL AND t.id IS NULL
UNION ALL SELECT 'topic_tag.tag 孤儿',      COUNT(*) FROM madong_portal.md_portal_forum_topic_tag tt LEFT JOIN madong_portal.md_portal_forum_tag g ON tt.tag_id = g.id WHERE g.id IS NULL
UNION ALL SELECT 'points.member_id 孤儿',   COUNT(*) FROM madong_portal.md_member_points p LEFT JOIN madong_portal.md_member m ON p.member_id = m.id WHERE m.id IS NULL
UNION ALL SELECT 'sign.member_id 孤儿',     COUNT(*) FROM madong_portal.md_member_sign s LEFT JOIN madong_portal.md_member m ON s.member_id = m.id WHERE m.id IS NULL;

-- D3. ID 不变校验（MIN/MAX 源目标一致）
SELECT 'member' AS tbl,
       (SELECT MIN(id) FROM madong_saas_portal.md_member) AS src_min, (SELECT MIN(id) FROM madong_portal.md_member) AS dst_min,
       (SELECT MAX(id) FROM madong_saas_portal.md_member) AS src_max, (SELECT MAX(id) FROM madong_portal.md_member) AS dst_max
UNION ALL
SELECT 'forum_topic',
       (SELECT MIN(id) FROM madong_saas_portal.md_portal_ask_question) AS src_min, (SELECT MIN(id) FROM madong_portal.md_portal_forum_topic) AS dst_min,
       (SELECT MAX(id) FROM madong_saas_portal.md_portal_ask_question) AS src_max, (SELECT MAX(id) FROM madong_portal.md_portal_forum_topic) AS dst_max;
