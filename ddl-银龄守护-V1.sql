-- ============================================================
-- 银龄守护 (SilverGuard) - 社区智慧养老平台
-- Database: ylsh
-- Engine:   MySQL 8.0 (UTF8MB4)
-- Version:  V1 MVP
-- Date:     2026-05-03
--
-- DDD Bounded Contexts (6):
--   1. Identity & Access (身份与权限)
--   2. Safety Guard (安全守护)
--   3. Life Service (生活服务)
--   4. Health Management (健康管理)
--   5. Emotional Companion (情感陪伴)
--   6. Community Admin (社区管理)
-- ============================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================
-- 0. 基础枚举/字典表
-- ============================================================

-- 地区表（省/市/区/街道/社区 五级）
CREATE TABLE sys_region (
    region_id      BIGINT       NOT NULL AUTO_INCREMENT COMMENT '地区ID',
    parent_id      BIGINT       DEFAULT NULL COMMENT '父级ID',
    region_name    VARCHAR(64)  NOT NULL COMMENT '地区名称',
    region_code    VARCHAR(20)  NOT NULL COMMENT '行政区划代码',
    level          TINYINT      NOT NULL DEFAULT 1 COMMENT '级别: 1省 2市 3区 4街道 5社区',
    sort_order     INT          DEFAULT 0 COMMENT '排序',
    status         TINYINT      NOT NULL DEFAULT 1 COMMENT '状态: 0禁用 1启用',
    created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (region_id),
    INDEX idx_parent (parent_id),
    INDEX idx_code (region_code),
    INDEX idx_level (level)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='行政区划表';

-- 数据字典
CREATE TABLE sys_dict (
    dict_id        BIGINT       NOT NULL AUTO_INCREMENT COMMENT '字典ID',
    dict_type      VARCHAR(64)  NOT NULL COMMENT '字典类型编码',
    dict_label     VARCHAR(128) NOT NULL COMMENT '字典标签',
    dict_value     VARCHAR(128) NOT NULL COMMENT '字典值',
    sort_order     INT          DEFAULT 0 COMMENT '排序',
    remark         VARCHAR(256) DEFAULT NULL COMMENT '备注',
    status         TINYINT      NOT NULL DEFAULT 1 COMMENT '状态: 0禁用 1启用',
    created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (dict_id),
    UNIQUE KEY uk_type_value (dict_type, dict_value),
    INDEX idx_type (dict_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='数据字典表';

-- ============================================================
-- 1. Identity & Access Context (身份与权限)
-- ============================================================

-- 用户基础表（所有角色的父表）
CREATE TABLE usr_user (
    user_id        BIGINT       NOT NULL AUTO_INCREMENT COMMENT '用户ID',
    phone          VARCHAR(20)  NOT NULL COMMENT '手机号（登录账号）',
    password_hash  VARCHAR(256) DEFAULT NULL COMMENT '密码哈希（可为空，支持微信免密登录）',
    nickname       VARCHAR(64)  DEFAULT NULL COMMENT '昵称',
    avatar_url     VARCHAR(512) DEFAULT NULL COMMENT '头像URL',
    gender         TINYINT      DEFAULT 0 COMMENT '性别: 0未知 1男 2女',
    openid_wechat  VARCHAR(128) DEFAULT NULL COMMENT '微信OpenID',
    unionid_wechat VARCHAR(128) DEFAULT NULL COMMENT '微信UnionID',
    status         TINYINT      NOT NULL DEFAULT 1 COMMENT '状态: 0禁用 1正常 2注销',
    last_login_at  DATETIME(3)  DEFAULT NULL COMMENT '最后登录时间',
    last_login_ip  VARCHAR(45)  DEFAULT NULL COMMENT '最后登录IP',
    created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (user_id),
    UNIQUE KEY uk_phone (phone),
    UNIQUE KEY uk_openid (openid_wechat),
    INDEX idx_unionid (unionid_wechat)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户基础表';

-- 老人档案表
CREATE TABLE usr_elderly (
    elderly_id     BIGINT       NOT NULL AUTO_INCREMENT COMMENT '老人档案ID',
    user_id        BIGINT       NOT NULL COMMENT '关联用户账号ID',
    name           VARCHAR(32)  NOT NULL COMMENT '姓名',
    id_card        VARCHAR(18)  DEFAULT NULL COMMENT '身份证号',
    gender         TINYINT      NOT NULL COMMENT '性别: 1男 2女',
    birth_date     DATE         DEFAULT NULL COMMENT '出生日期',
    age            TINYINT      DEFAULT NULL COMMENT '年龄（由应用层维护）',
    phone          VARCHAR(20)  DEFAULT NULL COMMENT '本人手机号',
    address        VARCHAR(256) DEFAULT NULL COMMENT '详细住址',
    region_id      BIGINT       DEFAULT NULL COMMENT '所属社区ID',
    longitude      DECIMAL(10,6) DEFAULT NULL COMMENT '经度',
    latitude       DECIMAL(10,6) DEFAULT NULL COMMENT '纬度',
    living_status  TINYINT      NOT NULL DEFAULT 1 COMMENT '居住状态: 1独居 2与配偶同住 3与子女同住 4养老院',
    health_level   TINYINT      NOT NULL DEFAULT 1 COMMENT '健康等级: 1良好 2基本自理 3需协助 4失能半失能 5失能',
    emergency_contact_name  VARCHAR(32) DEFAULT NULL COMMENT '紧急联系人姓名',
    emergency_contact_phone VARCHAR(20) DEFAULT NULL COMMENT '紧急联系人电话',
    blood_type     CHAR(2)     DEFAULT NULL COMMENT '血型: A B AB O',
    allergies      VARCHAR(512) DEFAULT NULL COMMENT '过敏史（JSON数组）',
    medical_history TEXT        DEFAULT NULL COMMENT '既往病史（JSON）',
    privacy_mode   TINYINT      NOT NULL DEFAULT 0 COMMENT '隐私模式: 0正常 1模糊画面 2关闭摄像头',
    sos_enabled    TINYINT      NOT NULL DEFAULT 1 COMMENT 'SOS开关: 0关 1开',
    profile_photo_url VARCHAR(512) DEFAULT NULL COMMENT '证件照URL',
    remark         VARCHAR(512) DEFAULT NULL COMMENT '备注',
    status         TINYINT      NOT NULL DEFAULT 1 COMMENT '状态: 0注销 1正常 2暂停服务',
    created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (elderly_id),
    UNIQUE KEY uk_user_id (user_id),
    INDEX idx_region (region_id),
    INDEX idx_living (living_status),
    INDEX idx_health (health_level),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='老人档案表';

-- 家属关联表（老人-家属 多对多）
CREATE TABLE usr_family_bind (
    bind_id        BIGINT       NOT NULL AUTO_INCREMENT COMMENT '绑定ID',
    elderly_id     BIGINT       NOT NULL COMMENT '老人档案ID',
    family_user_id BIGINT       NOT NULL COMMENT '家属用户ID',
    relation_type  VARCHAR(16)  NOT NULL COMMENT '关系: son daughter spouse sibling other',
    is_primary     TINYINT      NOT NULL DEFAULT 0 COMMENT '是否主联系人: 0否 1是',
    alert_enabled  TINYINT      NOT NULL DEFAULT 1 COMMENT '是否接收告警通知: 0否 1是',
    service_perm   TINYINT      NOT NULL DEFAULT 1 COMMENT '服务预约权限: 0无 1只读 2可下单',
    health_perm    TINYINT      NOT NULL DEFAULT 1 COMMENT '健康数据查看权限: 0无 1基础 2详细',
    video_perm     TINYINT      NOT NULL DEFAULT 1 COMMENT '视频探视权限: 0否 1是',
    bind_time      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '绑定时间',
    verify_status  TINYINT      NOT NULL DEFAULT 0 COMMENT '审核状态: 0待审核 1已通过 2已拒绝',
    verified_by    BIGINT       DEFAULT NULL COMMENT '审核人（老人或主联系人）',
    verified_at    DATETIME(3)  DEFAULT NULL COMMENT '审核时间',
    status         TINYINT      NOT NULL DEFAULT 1 COMMENT '状态: 0解绑 1生效',
    created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (bind_id),
    UNIQUE KEY uk_elderly_family (elderly_id, family_user_id),
    INDEX idx_family (family_user_id),
    INDEX idx_verify (verify_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='家属关联表';

-- 服务人员表
CREATE TABLE usr_service_worker (
    worker_id      BIGINT       NOT NULL AUTO_INCREMENT COMMENT '服务人员ID',
    user_id        BIGINT       NOT NULL COMMENT '关联用户账号ID',
    name           VARCHAR(32)  NOT NULL COMMENT '姓名',
    id_card        VARCHAR(18)  DEFAULT NULL COMMENT '身份证号',
    gender         TINYINT      NOT NULL COMMENT '性别: 1男 2女',
    phone          VARCHAR(20)  NOT NULL COMMENT '手机号',
    region_id      BIGINT       DEFAULT NULL COMMENT '所属街道/社区ID',
    worker_type    TINYINT      NOT NULL DEFAULT 1 COMMENT '人员类型: 1临时 2正式',
    service_tags   VARCHAR(256) DEFAULT NULL COMMENT '服务标签（JSON数组: meal,cleaning,accompany等）',
    id_card_front_url  VARCHAR(512) DEFAULT NULL COMMENT '身份证正面照',
    id_card_back_url   VARCHAR(512) DEFAULT NULL COMMENT '身份证背面照',
    cert_health_url    VARCHAR(512) DEFAULT NULL COMMENT '健康证照片',
    cert_no       VARCHAR(64)  DEFAULT NULL COMMENT '健康证编号',
    bank_account  VARCHAR(32)  DEFAULT NULL COMMENT '收款银行卡号',
    bank_name     VARCHAR(64)  DEFAULT NULL COMMENT '开户行',
    total_orders  INT          NOT NULL DEFAULT 0 COMMENT '累计接单数',
    completed_orders INT        NOT NULL DEFAULT 0 COMMENT '已完成单数',
    avg_rating    DECIMAL(2,1) DEFAULT NULL COMMENT '平均评分(1-5)',
    credit_score  INT          DEFAULT 100 COMMENT '信用分(0-200)',
    status        TINYINT      NOT NULL DEFAULT 0 COMMENT '状态: 0待审核 1已通过 2已拒绝 3停用 4已转正申请中',
    applied_formal_at DATETIME(3) DEFAULT NULL COMMENT '申请转正时间',
    reviewed_by   BIGINT       DEFAULT NULL COMMENT '审核人ID',
    reviewed_at   DATETIME(3)  DEFAULT NULL COMMENT '审核时间',
    review_remark VARCHAR(256) DEFAULT NULL COMMENT '审核备注',
    created_at    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (worker_id),
    UNIQUE KEY uk_user_id (user_id),
    INDEX idx_region (region_id),
    INDEX idx_type (worker_type),
    INDEX idx_status (status),
    INDEX idx_credit (credit_score)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='服务人员表';

-- 街道管理员表
CREATE TABLE usr_street_admin (
    admin_id       BIGINT       NOT NULL AUTO_INCREMENT COMMENT '管理员ID',
    user_id        BIGINT       NOT NULL COMMENT '关联用户账号ID',
    name           VARCHAR(32)  NOT NULL COMMENT '姓名',
    phone          VARCHAR(20)  NOT NULL COMMENT '手机号',
    region_id      BIGINT       NOT NULL COMMENT '所属街道ID',
    role_type      TINYINT      NOT NULL DEFAULT 1 COMMENT '角色: 1普通管理员 2超级管理员 3值班员',
    dept_name      VARCHAR(64)  DEFAULT NULL COMMENT '部门名称',
    status         TINYINT      NOT NULL DEFAULT 1 COMMENT '状态: 0禁用 1正常',
    created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (admin_id),
    UNIQUE KEY uk_user_id (user_id),
    INDEX idx_region (region_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='街道管理员表';

-- 合作机构表（保险公司/陪诊机构/家庭医生团队等）
CREATE TABLE usr_partner_org (
    org_id         BIGINT       NOT NULL AUTO_INCREMENT COMMENT '机构ID',
    org_name       VARCHAR(128) NOT NULL COMMENT '机构名称',
    org_type       TINYINT      NOT NULL COMMENT '类型: 1陪诊机构 2保险公司 3社区卫生中心 4家政公司 5餐饮供应商',
    contact_person VARCHAR(32)  DEFAULT NULL COMMENT '联系人',
    contact_phone  VARCHAR(20)  DEFAULT NULL COMMENT '联系电话',
    license_no     VARCHAR(64)  DEFAULT NULL COMMENT '营业执照/资质编号',
    address        VARCHAR(256) DEFAULT NULL COMMENT '地址',
    region_id      BIGINT       DEFAULT NULL COMMENT '覆盖区域ID',
    api_key        VARCHAR(128) DEFAULT NULL COMMENT 'API接入密钥',
    webhook_url    VARCHAR(512) DEFAULT NULL COMMENT '回调地址',
    contract_start DATE         DEFAULT NULL COMMENT '合作开始日期',
    contract_end   DATE         DEFAULT NULL COMMENT '合作结束日期',
    status         TINYINT      NOT NULL DEFAULT 0 COMMENT '状态: 0待审核 1合作中 2已终止',
    created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (org_id),
    INDEX idx_type (org_type),
    INDEX idx_region (region_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='合作机构表';

-- 设备绑定表（摄像头/可穿戴设备等）
CREATE TABLE usr_device (
    device_id      BIGINT       NOT NULL AUTO_INCREMENT COMMENT '设备ID',
    device_sn      VARCHAR(64)  NOT NULL COMMENT '设备序列号',
    device_type    TINYINT      NOT NULL COMMENT '设备类型: 1AI摄像头 2智能手环 3血压计 4血糖仪 5门磁传感器 6烟感报警器 7燃气报警器',
    device_model   VARCHAR(64)  DEFAULT NULL COMMENT '设备型号',
    manufacturer   VARCHAR(64)  DEFAULT NULL COMMENT '厂商',
    firmware_ver   VARCHAR(32)  DEFAULT NULL COMMENT '固件版本',
    elderly_id     BIGINT       NOT NULL COMMENT '关联老人ID',
    install_location VARCHAR(64) DEFAULT NULL COMMENT '安装位置描述（如"客厅"、"卧室"）',
    longitude      DECIMAL(10,6) DEFAULT NULL COMMENT '安装经度',
    latitude       DECIMAL(10,6) DEFAULT NULL COMMENT '安装纬度',
    is_online      TINYINT      NOT NULL DEFAULT 0 COMMENT '在线状态: 0离线 1在线',
    last_heartbeat DATETIME(3)  DEFAULT NULL COMMENT '最后心跳时间',
    status         TINYINT      NOT NULL DEFAULT 1 COMMENT '状态: 0停用 1正常 2故障',
    installed_at   DATETIME(3)  DEFAULT NULL COMMENT '安装时间',
    created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (device_id),
    UNIQUE KEY uk_sn (device_sn),
    INDEX idx_elderly (elderly_id),
    INDEX idx_type (device_type),
    INDEX idx_online (is_online)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='设备绑定表';


-- ============================================================
-- 2. Safety Guard Context (安全守护)
-- ============================================================

-- 安全告警记录表
CREATE TABLE saf_alert (
    alert_id       BIGINT       NOT NULL AUTO_INCREMENT COMMENT '告警ID',
    alert_no       VARCHAR(32)  NOT NULL COMMENT '告警编号（业务流水号）',
    elderly_id     BIGINT       NOT NULL COMMENT '老人ID',
    device_id      BIGINT       DEFAULT NULL COMMENT '触发设备ID',
    alert_type     TINYINT      NOT NULL COMMENT '告警类型: 1摔倒检测 2长时间未移动 3异常离床 4SOS按钮 5烟雾报警 6燃气泄漏 7心率异常 8血压异常',
    alert_level    TINYINT      NOT NULL COMMENT '紧急程度: P0致命 P1严重 P2中等 P3低',
    confidence     DECIMAL(5,2) DEFAULT NULL COMMENT 'AI检测置信度(0-100)',
    alert_time     DATETIME(3)  NOT NULL COMMENT '告警触发时间',
    location_desc  VARCHAR(128) DEFAULT NULL COMMENT '位置描述',
    snapshot_url   VARCHAR(512) DEFAULT NULL COMMENT '快照/截图URL',
    video_clip_url VARCHAR(512) DEFAULT NULL COMMENT '视频片段URL',
    -- 三级联动状态
    notify_family_at   DATETIME(3) DEFAULT NULL COMMENT '通知家属时间',
    family_responded_at DATETIME(3) DEFAULT NULL COMMENT '家属响应时间',
    family_response    TINYINT      DEFAULT NULL COMMENT '家属响应: 0未响应 1确认安全 2需要帮助 3误报取消',
    escalate_street_at DATETIME(3) DEFAULT NULL COMMENT '升级街道时间',
    street_admin_id    BIGINT       DEFAULT NULL COMMENT '处理街道管理员ID',
    street_responded_at DATETIME(3) DEFAULT NULL COMMENT '街道响应时间',
    street_action      TINYINT      DEFAULT NULL COMMENT '街道处置: 0未处理 1派员上门 2联系家属 3拨打120 4误报',
    escalate_120_at    DATETIME(3) DEFAULT NULL COMMENT '升级120时间',
    call_120_result    TINYINT      DEFAULT NULL COMMENT '120呼叫结果: 0未拨 1已接通 2占线 3失败',
    -- 取消信息
    cancel_reason  VARCHAR(128) DEFAULT NULL COMMENT '取消原因',
    cancelled_by   BIGINT       DEFAULT NULL COMMENT '取消人ID',
    cancelled_at   DATETIME(3)  DEFAULT NULL COMMENT '取消时间',
    -- 最终状态
    alert_status   TINYINT      NOT NULL DEFAULT 0 COMMENT '状态: 0待处理 1家属已响应 2街道已响应 3已派员 4120已联动 5已解决 6已取消 7误报',
    resolved_at    DATETIME(3)  DEFAULT NULL COMMENT '解决时间',
    resolve_remark VARCHAR(512) DEFAULT NULL COMMENT '解决备注',
    response_seconds INT         DEFAULT NULL COMMENT '总响应耗时(秒)',
    created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (alert_id),
    UNIQUE KEY uk_alert_no (alert_no),
    INDEX idx_elderly (elderly_id),
    INDEX idx_device (device_id),
    INDEX idx_type (alert_type),
    INDEX idx_level (alert_level),
    INDEX idx_status (alert_status),
    INDEX idx_time (alert_time),
    INDEX idx_alert_time (alert_time)  -- 街道后台聚合查询用
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='安全告警记录表';

-- 告警通知日志表（每次推送都记录）
CREATE TABLE saf_alert_notify (
    notify_id      BIGINT       NOT NULL AUTO_INCREMENT COMMENT '通知ID',
    alert_id       BIGINT       NOT NULL COMMENT '告警ID',
    channel        TINYINT      NOT NULL COMMENT '渠道: 1App推送 2短信 3微信模板消息 4语音电话 5站内信',
    target_id      BIGINT       NOT NULL COMMENT '接收人ID（家属/管理员）',
    target_type    TINYINT      NOT NULL COMMENT '接收人类型: 1家属 2街道管理员 3服务人员',
    send_status    TINYINT      NOT NULL DEFAULT 0 COMMENT '发送状态: 0待发 1成功 2失败',
    send_at        DATETIME(3)  DEFAULT NULL COMMENT '发送时间',
    read_at        DATETIME(3)  DEFAULT NULL COMMENT '阅读时间',
    error_msg      VARCHAR(256) DEFAULT NULL COMMENT '错误信息',
    created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (notify_id),
    INDEX idx_alert (alert_id),
    INDEX idx_target (target_id, target_type),
    INDEX idx_send_status (send_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='告警通知日志表';

-- AI 检测事件原始记录表
CREATE TABLE saf_ai_event (
    event_id       BIGINT       NOT NULL AUTO_INCREMENT COMMENT '事件ID',
    device_id      BIGINT       NOT NULL COMMENT '设备ID',
    elderly_id     BIGINT       NOT NULL COMMENT '老人ID',
    event_type     VARCHAR(32)  NOT NULL COMMENT '事件类型: fall immobility posture_abnormal bed_exit zone_violation',
    confidence     DECIMAL(5,2) NOT NULL COMMENT '置信度(0-100)',
    event_time     DATETIME(3)  NOT NULL COMMENT '事件发生时间',
    snapshot_url   VARCHAR(512) DEFAULT NULL COMMENT '截图URL',
    model_version  VARCHAR(32)  DEFAULT NULL COMMENT 'AI模型版本',
    raw_data_ref   VARCHAR(256) DEFAULT NULL COMMENT '原始数据引用（OSS路径等）',
    processed      TINYINT      NOT NULL DEFAULT 0 COMMENT '是否已生成告警: 0否 1是 2忽略(低于阈值)',
    related_alert_id BIGINT     DEFAULT NULL COMMENT '关联的告警ID',
    created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (event_id),
    INDEX idx_device (device_id),
    INDEX idx_elderly (elderly_id),
    INDEX idx_event_time (event_time),
    INDEX idx_processed (processed)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='AI检测事件原始记录表';


-- ============================================================
-- 3. Life Service Context (生活服务)
-- ============================================================

-- 服务类目表
CREATE TABLE svc_category (
    category_id    BIGINT       NOT NULL AUTO_INCREMENT COMMENT '类目ID',
    parent_id      BIGINT       DEFAULT NULL COMMENT '父级类目ID',
    category_name  VARCHAR(64)  NOT NULL COMMENT '类目名称',
    category_code  VARCHAR(32)  NOT NULL COMMENT '类目编码',
    icon_url       VARCHAR(512) DEFAULT NULL COMMENT '图标URL',
    description    VARCHAR(256) DEFAULT NULL COMMENT '描述',
    sort_order     INT          DEFAULT 0 COMMENT '排序',
    status         TINYINT      NOT NULL DEFAULT 1 COMMENT '状态: 0下架 1上架',
    created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (category_id),
    UNIQUE KEY uk_code (category_code),
    INDEX idx_parent (parent_id),
    INDEX idx_sort (sort_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='服务类目表';

-- 服务商品/SKU 表
CREATE TABLE svc_product (
    product_id     BIGINT       NOT NULL AUTO_INCREMENT COMMENT '商品ID',
    category_id    BIGINT       NOT NULL COMMENT '所属类目ID',
    product_name   VARCHAR(128) NOT NULL COMMENT '服务名称',
    product_desc   TEXT         DEFAULT NULL COMMENT '服务详情描述',
    cover_image    VARCHAR(512) DEFAULT NULL COMMENT '封面图',
    price_standard DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT '标准价格(元)',
    price_unit     VARCHAR(16)  NOT NULL DEFAULT '次' COMMENT '计价单位: 次 小时 天 月',
    duration_min   INT          DEFAULT NULL COMMENT '标准服务时长(分钟)',
    service_scope  VARCHAR(256) DEFAULT NULL COMMENT '服务范围说明',
    booking_rules  JSON         DEFAULT NULL COMMENT '预约规则（提前多久、时段等）',
    org_id         BIGINT       DEFAULT NULL COMMENT '提供服务的合作机构ID',
    status         TINYINT      NOT NULL DEFAULT 1 COMMENT '状态: 0下架 1上架',
    created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (product_id),
    INDEX idx_category (category_id),
    INDEX idx_org (org_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='服务商品表';

-- 服务订单表
CREATE TABLE svc_order (
    order_id       BIGINT       NOT NULL AUTO_INCREMENT COMMENT '订单ID',
    order_no       VARCHAR(32)  NOT NULL COMMENT '订单编号',
    elderly_id     BIGINT       NOT NULL COMMENT '服务对象（老人）ID',
    order_from     TINYINT      NOT NULL DEFAULT 1 COMMENT '下单来源: 1老人自己 2家属代下单 3街道安排',
    buyer_user_id  BIGINT       NOT NULL COMMENT '下单人用户ID',
    product_id     BIGINT       NOT NULL COMMENT '服务商品ID',
    -- 时间要求
    service_date   DATE         NOT NULL COMMENT '期望服务日期',
    time_slot_start TIME        DEFAULT NULL COMMENT '期望开始时段',
    time_slot_end   TIME        DEFAULT NULL COMMENT '期望结束时段',
    -- 地址
    service_address VARCHAR(256) DEFAULT NULL COMMENT '服务地址（默认老人住址）',
    contact_name   VARCHAR(32)  DEFAULT NULL COMMENT '联系人',
    contact_phone  VARCHAR(20)  DEFAULT NULL COMMENT '联系电话',
    -- 价格
    original_price DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT '原价',
    discount_amount DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT '优惠金额',
    final_price    DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT '实付金额',
    pay_method     TINYINT      DEFAULT NULL COMMENT '支付方式: 1微信 2支付宝 3月结(街道) 4免费',
    pay_status     TINYINT      NOT NULL DEFAULT 0 COMMENT '支付状态: 0未支付 1已支付 2已退款 3无需支付',
    paid_at        DATETIME(3)  DEFAULT NULL COMMENT '支付时间',
    -- 状态机
    order_status   TINYINT      NOT NULL DEFAULT 0 COMMENT '状态: 0待支付 1待接单 2已接单 3已签到 4服务中 5已完成 6已评价 7已取消 8退款中',
    -- 接单信息
    worker_id      BIGINT       DEFAULT NULL COMMENT '接单服务人员ID',
    accepted_at    DATETIME(3)  DEFAULT NULL COMMENT '接单时间',
    -- 签到签退
    checkin_at     DATETIME(3)  DEFAULT NULL COMMENT '签到时间',
    checkin_lat    DECIMAL(10,6) DEFAULT NULL COMMENT '签到纬度',
    checkin_lng    DECIMAL(10,6) DEFAULT NULL COMMENT '签到经度',
    checkout_at    DATETIME(3)  DEFAULT NULL COMMENT '签退时间',
    checkout_lat   DECIMAL(10,6) DEFAULT NULL COMMENT '签退纬度',
    checkout_lng   DECIMAL(10,6) DEFAULT NULL COMMENT '签退经度',
    -- 完成信息
    finish_photos  JSON         DEFAULT NULL COMMENT '完成照片URL列表',
    finish_remark  VARCHAR(512) DEFAULT NULL COMMENT '完成备注',
    completed_at   DATETIME(3)  DEFAULT NULL COMMENT '完成时间',
    -- 评价
    rating         TINYINT      DEFAULT NULL COMMENT '评分(1-5)',
    review_content VARCHAR(512) DEFAULT NULL COMMENT '评价内容',
    reviewed_at    DATETIME(3)  DEFAULT NULL COMMENT '评价时间',
    -- 取消/退款
    cancel_reason  VARCHAR(256) DEFAULT NULL COMMENT '取消原因',
    cancelled_by   BIGINT       DEFAULT NULL COMMENT '取消人ID',
    cancelled_at   DATETIME(3)  DEFAULT NULL COMMENT '取消时间',
    refund_amount  DECIMAL(10,2) DEFAULT NULL COMMENT '退款金额',
    refunded_at    DATETIME(3)  DEFAULT NULL COMMENT '退款时间',
    -- 扩展字段
    remark         VARCHAR(512) DEFAULT NULL COMMENT '订单备注',
    ext_info       JSON         DEFAULT NULL COMMENT '扩展信息',
    version        INT          NOT NULL DEFAULT 1 COMMENT '乐观锁版本号',
    created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (order_id),
    UNIQUE KEY uk_order_no (order_no),
    INDEX idx_elderly (elderly_id),
    INDEX idx_buyer (buyer_user_id),
    INDEX idx_worker (worker_id),
    INDEX idx_product (product_id),
    INDEX idx_status (order_status),
    INDEX idx_service_date (service_date),
    INDEX idx_pay_status (pay_status),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='服务订单表';

-- 订单操作日志表（状态变更审计）
CREATE TABLE svc_order_log (
    log_id         BIGINT       NOT NULL AUTO_INCREMENT COMMENT '日志ID',
    order_id       BIGINT       NOT NULL COMMENT '订单ID',
    action         VARCHAR(32)  NOT NULL COMMENT '操作动作: create pay accept checkin start complete cancel refund evaluate assign',
    from_status    TINYINT      DEFAULT NULL COMMENT '操作前状态',
    to_status      TINYINT      DEFAULT NULL COMMENT '操作后状态',
    operator_id    BIGINT       DEFAULT NULL COMMENT '操作人ID',
    operator_type  TINYINT      DEFAULT NULL COMMENT '操作人类型: 1系统 2老人 3家属 4服务人员 5街道管理员',
    remark         VARCHAR(512) DEFAULT NULL COMMENT '操作备注',
    created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (log_id),
    INDEX idx_order (order_id),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='订单操作日志表';

-- 服务人员钱包/结算表
CREATE TABLE svc_worker_wallet (
    wallet_id      BIGINT       NOT NULL AUTO_INCREMENT COMMENT '钱包ID',
    worker_id      BIGINT       NOT NULL COMMENT '服务人员ID',
    balance        DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT '可用余额(元)',
    frozen_amount  DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT '冻结金额(元)',
    total_income   DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT '累计收入(元)',
    total_withdrawn DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT '累计提现(元)',
    updated_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (wallet_id),
    UNIQUE KEY uk_worker (worker_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='服务人员钱包表';

-- 结算/交易流水表
CREATE TABLE svc_settlement (
    settle_id      BIGINT       NOT NULL AUTO_INCREMENT COMMENT '结算ID',
    order_id       BIGINT       NOT NULL COMMENT '关联订单ID',
    worker_id      BIGINT       NOT NULL COMMENT '服务人员ID',
    type           TINYINT      NOT NULL COMMENT '类型: 1收入 2提现 3退回 4奖励 5惩罚',
    amount         DECIMAL(10,2) NOT NULL COMMENT '金额(元)',
    balance_before DECIMAL(10,2) NOT NULL COMMENT '变动前余额',
    balance_after  DECIMAL(10,2) NOT NULL COMMENT '变动后余额',
    title          VARCHAR(128) NOT NULL COMMENT '摘要',
    ref_no         VARCHAR(64)  DEFAULT NULL COMMENT '关联流水号（支付平台等）',
    status         TINYINT      NOT NULL DEFAULT 1 COMMENT '状态: 0待结算 1已完成 2失败',
    created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (settle_id),
    INDEX idx_worker (worker_id),
    INDEX idx_order (order_id),
    INDEX idx_type (type),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='结算流水表';


-- ============================================================
-- 4. Health Management Context (健康管理)
-- ============================================================

-- 用药计划表
CREATE TABLE hlt_medication_plan (
    plan_id        BIGINT       NOT NULL AUTO_INCREMENT COMMENT '计划ID',
    elderly_id     BIGINT       NOT NULL COMMENT '老人ID',
    drug_name      VARCHAR(64)  NOT NULL COMMENT '药品名称',
    drug_generic   VARCHAR(64)  DEFAULT NULL COMMENT '通用名',
    dosage         VARCHAR(32)  NOT NULL COMMENT '剂量（如"1片"、"5ml"）',
    frequency      TINYINT      NOT NULL COMMENT '频次: 1每日一次 2每日两次 3每日三次 4每周一次 5按需',
    take_times     JSON         NOT NULL COMMENT '服药时间点（如["08:00","20:00"]）',
    route          VARCHAR(16)  DEFAULT '口服' COMMENT '给药途径: 口服 外用 舌下 吸入 注射',
    start_date     DATE         NOT NULL COMMENT '开始日期',
    end_date       DATE         DEFAULT NULL COMMENT '结束日期（NULL表示长期）',
    prescriber     VARCHAR(64)  DEFAULT NULL COMMENT '开方医生',
    source         TINYINT      DEFAULT 1 COMMENT '来源: 1手动录入 2医生同步 3OCR识别',
    stock_count    INT          DEFAULT NULL COMMENT '剩余数量',
    reminder_advance_min INT     DEFAULT 15 COMMENT '提前提醒(分钟)',
    status         TINYINT      NOT NULL DEFAULT 1 COMMENT '状态: 0停用 1使用中 2已完成',
    created_by     BIGINT       DEFAULT NULL COMMENT '创建人（家属或医生）',
    created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (plan_id),
    INDEX idx_elderly (elderly_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用药计划表';

-- 用药提醒记录表
CREATE TABLE hlt_medication_reminder (
    reminder_id    BIGINT       NOT NULL AUTO_INCREMENT COMMENT '提醒ID',
    plan_id        BIGINT       NOT NULL COMMENT '用药计划ID',
    elderly_id     BIGINT       NOT NULL COMMENT '老人ID',
    scheduled_time DATETIME(3)  NOT NULL COMMENT '计划服药时间',
    sent_at        DATETIME(3)  DEFAULT NULL COMMENT '提醒发送时间',
    send_channel   TINYINT      DEFAULT NULL COMMENT '发送渠道: 1App推送 2语音 3短信',
    taken_at       DATETIME(3)  DEFAULT NULL COMMENT '实际服药时间',
    taken_status   TINYINT      DEFAULT 0 COMMENT '服药状态: 0未确认 1已服用 2跳过 3忘记',
    skip_reason    VARCHAR(128) DEFAULT NULL COMMENT '跳过原因',
    created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (reminder_id),
    INDEX idx_plan (plan_id),
    INDEX idx_elderly (elderly_id),
    INDEX idx_scheduled (scheduled_time),
    INDEX idx_taken (taken_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用药提醒记录表';

-- 健康数据指标定义表
CREATE TABLE hlt_metric_def (
    metric_id      BIGINT       NOT NULL AUTO_INCREMENT COMMENT '指标ID',
    metric_code    VARCHAR(32)  NOT NULL COMMENT '指标编码',
    metric_name    VARCHAR(64)  NOT NULL COMMENT '指标名称',
    unit           VARCHAR(16)  DEFAULT NULL COMMENT '单位',
    category       TINYINT      NOT NULL COMMENT '分类: 1生命体征 2血糖 3血氧 4体重 5睡眠 6运动',
    normal_min     DECIMAL(10,2) DEFAULT NULL COMMENT '正常范围下限',
    normal_max     DECIMAL(10,2) DEFAULT NULL COMMENT '正常范围上限',
    warn_min       DECIMAL(10,2) DEFAULT NULL COMMENT '预警下限',
    warn_max       DECIMAL(10,2) DEFAULT NULL COMMENT '预警上限',
    danger_min     DECIMAL(10,2) DEFAULT NULL COMMENT '危险下限',
    danger_max     DECIMAL(10,2) DEFAULT NULL COMMENT '危险上限',
    color_rule     JSON         DEFAULT NULL COMMENT '颜色规则配置',
    sort_order     INT          DEFAULT 0 COMMENT '排序',
    status         TINYINT      NOT NULL DEFAULT 1 COMMENT '状态',
    created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (metric_id),
    UNIQUE KEY uk_code (metric_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='健康数据指标定义表';

-- 健康数据记录表（时序数据，按月分区）
CREATE TABLE hlt_health_data (
    data_id        BIGINT       NOT NULL AUTO_INCREMENT COMMENT '数据ID',
    elderly_id     BIGINT       NOT NULL COMMENT '老人ID',
    device_id      BIGINT       DEFAULT NULL COMMENT '采集设备ID',
    metric_code    VARCHAR(32)  NOT NULL COMMENT '指标编码',
    value_num      DECIMAL(10,2) DEFAULT NULL COMMENT '数值型值',
    value_str      VARCHAR(64)  DEFAULT NULL COMMENT '文本型值',
    value_extra    JSON         DEFAULT NULL COMMENT '扩展值（如血压的收缩压/舒张压）',
    measure_time   DATETIME(3)  NOT NULL COMMENT '测量时间',
    upload_time    DATetime(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '上传时间',
    data_source    TINYINT      NOT NULL DEFAULT 1 COMMENT '来源: 1蓝牙设备 2手动录入 3AI语音识别 4医生录入',
    is_abnormal    TINYINT      DEFAULT 0 COMMENT '是否异常: 0正常 1偏高 2偏低 3危险',
    created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (data_id),
    INDEX idx_elderly_metric_time (elderly_id, metric_code, measure_time),
    INDEX idx_measure_time (measure_time),
    INDEX idx_device (device_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='健康数据记录表';

-- 家庭医生签约表
CREATE TABLE hlt_doctor_binding (
    binding_id     BIGINT       NOT NULL AUTO_INCREMENT COMMENT '签约ID',
    elderly_id     BIGINT       NOT NULL COMMENT '老人ID',
    doctor_name    VARCHAR(32)  NOT NULL COMMENT '医生姓名',
    doctor_phone   VARCHAR(20)  DEFAULT NULL COMMENT '医生手机号',
    hospital_name  VARCHAR(128) DEFAULT NULL COMMENT '所属医疗机构',
    department     VARCHAR(64)  DEFAULT NULL COMMENT '科室',
    org_id         BIGINT       DEFAULT NULL COMMENT '关联合作机构ID',
    sign_date      DATE         NOT NULL COMMENT '签约日期',
    expire_date    DATE         DEFAULT NULL COMMENT '到期日期',
    status         TINYINT      NOT NULL DEFAULT 1 COMMENT '状态: 0已解约 1有效 2过期',
    created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (binding_id),
    INDEX idx_elderly (elderly_id),
    INDEX idx_doctor (doctor_phone),
    INDEX idx_org (org_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='家庭医生签约表';

-- 健康异常预警记录表
CREATE TABLE hlt_health_alert (
    alert_id       BIGINT       NOT NULL AUTO_INCREMENT COMMENT '预警ID',
    elderly_id     BIGINT       NOT NULL COMMENT '老人ID',
    metric_code    VARCHAR(32)  NOT NULL COMMENT '指标编码',
    alert_level    TINYINT      NOT NULL COMMENT '等级: 1提示 2警告 3危险',
    alert_value    DECIMAL(10,2) NOT NULL COMMENT '触发值',
    normal_range   VARCHAR(64)  DEFAULT NULL COMMENT '正常范围描述',
    continuous_days INT         NOT NULL DEFAULT 1 COMMENT '连续异常天数',
    alert_time     DATETIME(3)  NOT NULL COMMENT '预警时间',
    notify_family  TINYINT      NOT NULL DEFAULT 0 COMMENT '是否通知家属: 0否 1是',
    notify_doctor  TINYINT      NOT NULL DEFAULT 0 COMMENT '是否通知医生: 0否 1是',
    resolved       TINYINT      NOT NULL DEFAULT 0 COMMENT '是否恢复: 0否 1是',
    resolved_at    DATETIME(3)  DEFAULT NULL COMMENT '恢复正常时间',
    created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (alert_id),
    INDEX idx_elderly (elderly_id),
    INDEX idx_metric (metric_code),
    INDEX idx_level (alert_level),
    INDEX idx_time (alert_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='健康异常预警记录表';


-- ============================================================
-- 5. Emotional Companion Context (情感陪伴)
-- ============================================================

-- AI 对话会话表
CREATE TABLE cmp_chat_session (
    session_id     BIGINT       NOT NULL AUTO_INCREMENT COMMENT '会话ID',
    elderly_id     BIGINT       NOT NULL COMMENT '老人ID',
    initiator_type TINYINT      NOT NULL DEFAULT 1 COMMENT '发起方式: 1老人主动 2定时主动关怀 3家属远程发起',
    started_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '开始时间',
    ended_at       DATETIME(3)  DEFAULT NULL COMMENT '结束时间',
    message_count  INT          NOT NULL DEFAULT 0 COMMENT '消息数',
    duration_sec   INT          DEFAULT NULL COMMENT '持续时长(秒)',
    sentiment_avg  DECIMAL(3,2) DEFAULT NULL COMMENT '情感均值(-1~1)',
    risk_flag     TINYINT      NOT NULL DEFAULT 0 COMMENT '风险标记: 0正常 1消极倾向 2自伤倾向 3高危',
    summary        TEXT        DEFAULT NULL COMMENT '会话摘要(AI生成)',
    created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (session_id),
    INDEX idx_elderly (elderly_id),
    INDEX idx_started (started_at),
    INDEX idx_risk (risk_flag)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='AI对话会话表';

-- AI 对话消息表
CREATE TABLE cmp_chat_message (
    message_id     BIGINT       NOT NULL AUTO_INCREMENT COMMENT '消息ID',
    session_id     BIGINT       NOT NULL COMMENT '会话ID',
    role           TINYINT      NOT NULL COMMENT '角色: 1老人(user) 2AI(assistant) 3系统(system)',
    content_type   TINYINT      NOT NULL DEFAULT 1 COMMENT '内容类型: 1文本 2语音(ASR转文本后) 3图片',
    content_text   TEXT         NOT NULL COMMENT '消息文本',
    voice_url      VARCHAR(512) DEFAULT NULL COMMENT '语音文件URL（原始录音）',
    sentiment      DECIMAL(3,2) DEFAULT NULL COMMENT '情感得分(-1~1)',
    emotion_labels JSON         DEFAULT NULL COMMENT '情绪标签（如["sad","lonely"]）',
    model_version  VARCHAR(32)  DEFAULT NULL COMMENT '模型版本',
    token_count    INT          DEFAULT NULL COMMENT 'Token消耗数',
    latency_ms     INT          DEFAULT NULL COMMENT '响应延迟(毫秒)',
    created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (message_id),
    INDEX idx_session (session_id),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='AI对话消息表';

-- 远程视频探视记录表
CREATE TABLE cmp_video_visit (
    visit_id       BIGINT       NOT NULL AUTO_INCREMENT COMMENT '探视ID',
    elderly_id     BIGINT       NOT NULL COMMENT '老人ID',
    caller_user_id BIGINT       NOT NULL COMMENT '发起人家属用户ID',
    call_type      TINYINT      NOT NULL DEFAULT 1 COMMENT '类型: 1语音通话 2视频通话',
    started_at     DATETIME(3)  NOT NULL COMMENT '开始时间',
    ended_at       DATETIME(3)  DEFAULT NULL COMMENT '结束时间',
    duration_sec   INT          DEFAULT NULL COMMENT '通话时长(秒)',
    call_status    TINYINT      NOT NULL DEFAULT 0 COMMENT '状态: 0未接听 1进行中 2已挂断 3未接通 4老人拒接',
    hangup_side    TINYINT      DEFAULT NULL COMMENT '挂断方: 1家属 2老人 3超时',
    quality_score  TINYINT      DEFAULT NULL COMMENT '通话质量评分(1-5)',
    created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (visit_id),
    INDEX idx_elderly (elderly_id),
    INDEX idx_caller (caller_user_id),
    INDEX idx_started (started_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='远程视频探视记录表';

-- AI 陪伴偏好设置表
CREATE TABLE cmp_companion_pref (
    pref_id        BIGINT       NOT NULL AUTO_INCREMENT COMMENT '偏好ID',
    elderly_id     BIGINT       NOT NULL COMMENT '老人ID',
    nickname_ai    VARCHAR(32)  DEFAULT '小银' COMMENT 'AI助手称呼',
    voice_type     VARCHAR(32)  DEFAULT 'female_gentle' COMMENT '语音风格',
    topics_interest JSON        DEFAULT NULL COMMENT '感兴趣话题（如["戏曲","新闻","养生"]）',
    chat_frequency TINYINT      NOT NULL DEFAULT 1 COMMENT '主动聊天频率: 1每天1次 2每天2次 3每天3次',
    active_hours_start TIME     DEFAULT '08:00' COMMENT '活跃时段开始',
    active_hours_end   TIME     DEFAULT '20:00' COMMENT '活跃时段结束',
    avoid_topics   JSON         DEFAULT NULL COMMENT '避忌话题',
    personality    VARCHAR(32)  DEFAULT 'warm' COMMENT 'AI性格设定: warm lively calm professional',
    memory_context TEXT         DEFAULT NULL COMMENT '长期记忆上下文',
    updated_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (pref_id),
    UNIQUE KEY uk_elderly (elderly_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='AI陪伴偏好设置表';


-- ============================================================
-- 6. Community Admin Context (社区管理)
-- ============================================================

-- 街道/社区配置表
CREATE TABLE cmm_region_config (
    config_id      BIGINT       NOT NULL AUTO_INCREMENT COMMENT '配置ID',
    region_id      BIGINT       NOT NULL COMMENT '区域ID（街道/社区）',
    config_key     VARCHAR(64)  NOT NULL COMMENT '配置键',
    config_value   TEXT         NOT NULL COMMENT '配置值',
    description    VARCHAR(256) DEFAULT NULL COMMENT '说明',
    updated_by     BIGINT       DEFAULT NULL COMMENT '最后更新人',
    updated_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (config_id),
    UNIQUE KEY uk_region_key (region_id, config_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='区域配置表';

-- 工单/任务表（街道内部工单）
CREATE TABLE cmm_ticket (
    ticket_id      BIGINT       NOT NULL AUTO_INCREMENT COMMENT '工单ID',
    ticket_no      VARCHAR(32)  NOT NULL COMMENT '工单编号',
    region_id      BIGINT       NOT NULL COMMENT '所属区域ID',
    ticket_type    TINYINT      NOT NULL COMMENT '类型: 1入户走访 2设备安装 3投诉处理 4服务协调 5其他',
    priority       TINYINT      NOT NULL DEFAULT 2 COMMENT '优先级: 1高 2中 3低',
    title          VARCHAR(128) NOT NULL COMMENT '标题',
    description    TEXT         DEFAULT NULL COMMENT '详细描述',
    elderly_id     BIGINT       DEFAULT NULL COMMENT '关联老人ID',
    reporter_id    BIGINT       DEFAULT NULL COMMENT '上报人ID',
    reporter_type  TINYINT      DEFAULT NULL COMMENT '上报人类型: 1老人 2家属 3服务人员 4管理员',
    assignee_id    BIGINT       DEFAULT NULL COMMENT '处理人ID',
    ticket_status  TINYINT      NOT NULL DEFAULT 0 COMMENT '状态: 0待处理 1处理中 2待确认 3已完成 4已关闭 5已撤销',
    due_date       DATE         DEFAULT NULL COMMENT '期望完成日期',
    resolved_at    DATETIME(3)  DEFAULT NULL COMMENT '解决时间',
    resolution     VARCHAR(512) DEFAULT NULL COMMENT '解决方案',
    satisfaction   TINYINT      DEFAULT NULL COMMENT '满意度(1-5)',
    created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (ticket_id),
    UNIQUE KEY uk_ticket_no (ticket_no),
    INDEX idx_region (region_id),
    INDEX idx_elderly (elderly_id),
    INDEX idx_assignee (assignee_id),
    INDEX idx_status (ticket_status),
    INDEX idx_priority (priority)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='工单表';

-- 统计快照表（按天聚合，用于仪表盘和报表）
CREATE TABLE cmm_stats_snapshot (
    snapshot_id    BIGINT       NOT NULL AUTO_INCREMENT COMMENT '快照ID',
    stat_date      DATE         NOT NULL COMMENT '统计日期',
    region_id      BIGINT       NOT NULL COMMENT '区域ID',
    -- 老人统计
    total_elders   INT          DEFAULT 0 COMMENT '总老人数',
    active_elders  INT          DEFAULT 0 COMMENT '活跃老人数',
    new_elders     INT          DEFAULT 0 COMMENT '新增老人数',
    -- 告警统计
    total_alerts   INT          DEFAULT 0 COMMENT '总告警数',
    p0_alerts      INT          DEFAULT 0 COMMENT 'P0告警数',
    false_alerts   INT          DEFAULT 0 COMMENT '误报数',
    avg_response_sec INT        DEFAULT 0 COMMENT '平均响应时长(秒)',
    -- 服务统计
    total_orders   INT          DEFAULT 0 COMMENT '总订单数',
    completed_orders INT        DEFAULT 0 COMMENT '完成订单数',
    total_workers  INT          DEFAULT 0 COMMENT '注册服务人员数',
    active_workers INT          DEFAULT 0 COMMENT '活跃服务人员数',
    -- 健康统计
    med_reminders  INT          DEFAULT 0 COMMENT '用药提醒次数',
    med_compliance_rate DECIMAL(5,2) DEFAULT 0 COMMENT '用药依从率(%)',
    health_data_count INT       DEFAULT 0 COMMENT '健康数据条数',
    -- 陪伴统计
    ai_chat_count  INT          DEFAULT 0 COMMENT 'AI对话次数',
    video_visit_count INT       DEFAULT 0 COMMENT '视频探视次数',
    created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (snapshot_id),
    UNIQUE KEY uk_date_region (stat_date, region_id),
    INDEX idx_date (stat_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='统计快照表';

-- 操作日志表（全局审计）
CREATE TABLE cmm_audit_log (
    log_id         BIGINT       NOT NULL AUTO_INCREMENT COMMENT '日志ID',
    operator_id    BIGINT       DEFAULT NULL COMMENT '操作人ID',
    operator_name  VARCHAR(32)  DEFAULT NULL COMMENT '操作人姓名',
    operator_type  TINYINT      DEFAULT NULL COMMENT '操作人类型: 1老人 2家属 3服务人员 4街道管理员 5系统',
    module         VARCHAR(32)  NOT NULL COMMENT '模块: safety service health companion admin system',
    action         VARCHAR(32)  NOT NULL COMMENT '操作动作',
    target_type    VARCHAR(32)  DEFAULT NULL COMMENT '对象类型',
    target_id      BIGINT       DEFAULT NULL COMMENT '对象ID',
    detail         TEXT         DEFAULT NULL COMMENT '操作详情（JSON）',
    ip_address     VARCHAR(45)  DEFAULT NULL COMMENT 'IP地址',
    user_agent     VARCHAR(512) DEFAULT NULL COMMENT 'User-Agent',
    created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (log_id),
    INDEX idx_operator (operator_id),
    INDEX idx_module (module),
    INDEX idx_target (target_type, target_id),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='操作审计日志表';

-- ============================================================
-- 初始化数据
-- ============================================================

-- 服务类目初始数据
INSERT INTO svc_category (category_id, parent_id, category_name, category_code, sort_order) VALUES
(1, NULL, '生活照料', 'life_care', 1),
(2, 1, '上门送餐', 'meal_delivery', 1),
(3, 1, '家政保洁', 'house_cleaning', 2),
(4, 1, '陪同服务', 'accompany_service', 3),
(5, 4, '陪诊就医', 'medical_accompany', 1),
(6, 4, '代买代办', 'errand_service', 2),
(7, NULL, '健康服务', 'health_service', 2);

-- 健康指标初始数据
INSERT INTO hlt_metric_def (metric_code, metric_name, unit, category, normal_min, normal_max, warn_min, warn_max, danger_min, danger_max, sort_order) VALUES
('systolic', '收缩压(高压)', 'mmHg', 1, 90, 140, 80, 160, 70, 180, 1),
('diastolic', '舒张压(低压)', 'mmHg', 1, 60, 90, 50, 100, 40, 110, 2),
('heart_rate', '心率', 'bpm', 1, 60, 100, 50, 120, 40, 150, 3),
('blood_oxygen', '血氧饱和度', '%', 4, 95, 100, 90, 100, 85, 100, 4),
('blood_glucose_fasting', '空腹血糖', 'mmol/L', 2, 3.9, 6.1, 3.0, 7.0, 2.5, 9.0, 5),
('blood_glucose_2h', '餐后2h血糖', 'mmol/L', 2, 3.9, 7.8, 3.0, 11.0, 2.5, 15.0, 6),
('body_weight', '体重', 'kg', 5, NULL, NULL, NULL, NULL, NULL, NULL, 7),
('body_temperature', '体温', '°C', 1, 36.0, 37.3, 35.5, 37.8, 35.0, 39.0, 8);

-- 字典初始数据
INSERT INTO sys_dict (dict_type, dict_label, dict_value, sort_order) VALUES
('alert_type', '摔倒检测', '1', 1),
('alert_type', '长时间未移动', '2', 2),
('alert_type', '异常离床', '3', 3),
('alert_type', 'SOS按钮', '4', 4),
('alert_type', '烟雾报警', '5', 5),
('alert_type', '燃气泄漏', '6', 6),
('alert_type', '心率异常', '7', 7),
('alert_type', '血压异常', '8', 8),
('relation_type', '子女', 'son', 1),
('relation_type', '女儿', 'daughter', 2),
('relation_type', '配偶', 'spouse', 3),
('relation_type', '兄弟姐妹', 'sibling', 4),
('relation_type', '其他', 'other', 5),
('living_status', '独居', '1', 1),
('living_status', '与配偶同住', '2', 2),
('living_status', '与子女同住', '3', 3),
('living_status', '养老院', '4', 4);

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- DDL 完成
-- 总计: 30 张表
--   基础:    2 张 (sys_region, sys_dict)
--   身份域:  6 张 (usr_user, usr_elderly, usr_family_bind, usr_service_worker, usr_street_admin, usr_partner_org, usr_device) → 实际7张含device
--   安全域:  3 张 (saf_alert, saf_alert_notify, saf_ai_event)
--   服务域:  5 张 (svc_category, svc_product, svc_order, svc_order_log, svc_worker_wallet, svc_settlement) → 实际6张含settlement
--   健康域:  5 张 (hlt_medication_plan, hlt_medication_reminder, hlt_metric_def, hlt_health_data, hlt_doctor_binding, hlt_health_alert) → 实际6张含health_alert
--   陪伴域:  4 张 (cmp_chat_session, cmp_chat_message, cmp_video_visit, cmp_companion_pref)
--   管理域:  4 张 (cmm_region_config, cmm_ticket, cmm_stats_snapshot, cmm_audit_log)
-- ============================================================
