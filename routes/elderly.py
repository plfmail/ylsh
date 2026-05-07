# -*- coding: utf-8 -*-
"""老人管理路由 · 老人列表 / 详情 / 信息维护"""

from flask import Blueprint, render_template, request, jsonify
from models import (
    db, UsrElderly, UsrDevice, UsrFamilyBind,
    HltHealthData, HltMedicationPlan, UsrUser,
    SafAlert, SvcOrder, SvcProduct,
)

elderly_bp = Blueprint('elderly', __name__)

# 性别映射
GENDER_MAP = {0: '未知', 1: '男', 2: '女'}

# 健康等级映射
HEALTH_LEVEL_MAP = {
    1: '健康',
    2: '基本健康',
    3: '一般',
    4: '较弱',
    5: '虚弱',
}

# 居住状态映射
LIVING_STATUS_MAP = {
    1: '独居',
    2: '与配偶同住',
    3: '与子女同住',
    4: '养老机构',
}

# 告警类型映射
ALERT_TYPE_MAP = {1: '摔倒', 2: '长时间无活动', 3: '离开安全区域', 4: '紧急求助', 5: '设备异常'}

# 告警等级映射
ALERT_LEVEL_MAP = {1: '低', 2: '中', 3: '高', 4: '紧急'}

# 告警状态映射
ALERT_STATUS_MAP = {0: '待处理', 1: '处理中', 2: '已解决', 3: '已忽略', 4: '误报'}

# 订单状态映射
ORDER_STATUS_MAP = {0: '待支付', 1: '已支付', 2: '已接单', 3: '服务中', 4: '已完成', 5: '已取消', 6: '已退款', 7: '申诉中'}


@elderly_bp.route('/elderly')
def elderly_list():
    """老人列表 · 分页+搜索+按健康等级/居住状态筛选"""
    page = request.args.get('page', 1, type=int)
    keyword = request.args.get('keyword', '').strip()
    health_level = request.args.get('health_level', type=int)
    living_status = request.args.get('living_status', type=int)

    query = UsrElderly.query.filter(UsrElderly.status == 1)

    # 搜索：姓名/电话/身份证
    if keyword:
        query = query.filter(
            db.or_(
                UsrElderly.name.contains(keyword),
                UsrElderly.phone.contains(keyword),
                UsrElderly.id_card.contains(keyword),
            )
        )

    # 按健康等级筛选
    if health_level is not None:
        query = query.filter(UsrElderly.health_level == health_level)

    # 按居住状态筛选
    if living_status is not None:
        query = query.filter(UsrElderly.living_status == living_status)

    query = query.order_by(UsrElderly.created_at.desc())
    pagination = query.paginate(page=page, per_page=20, error_out=False)

    elders = []
    for e in pagination.items:
        # 统计设备数
        device_count = db.session.query(UsrDevice).filter_by(elderly_id=e.elderly_id).count()
        elders.append({
            'elderly_id': e.elderly_id,
            'name': e.name,
            'gender': GENDER_MAP.get(e.gender, '未知'),
            'age': e.age,
            'phone': e.phone or '',
            'address': e.address or '',
            'health_level': e.health_level,
            'health_level_text': HEALTH_LEVEL_MAP.get(e.health_level, f'等级{e.health_level}'),
            'living_status': e.living_status,
            'living_status_text': LIVING_STATUS_MAP.get(e.living_status, f'状态{e.living_status}'),
            'device_count': device_count,
            'sos_enabled': e.sos_enabled,
            'created_at': e.created_at.strftime('%Y-%m-%d') if e.created_at else '',
        })

    return render_template('elderly.html',
                           elders=elders,
                           pagination=pagination,
                           keyword=keyword,
                           current_health=health_level,
                           current_living=living_status,
                           health_level_map=HEALTH_LEVEL_MAP,
                           living_status_map=LIVING_STATUS_MAP)


@elderly_bp.route('/elderly/<int:elderly_id>')
def elderly_detail(elderly_id):
    """老人详情 · 基本信息/设备列表/家属绑定/健康数据"""
    elderly = UsrElderly.query.get_or_404(elderly_id)

    # 设备列表
    devices = UsrDevice.query.filter_by(elderly_id=elderly_id).all()

    # 家属绑定
    family_binds = UsrFamilyBind.query.filter_by(elderly_id=elderly_id).all()

    # 最近健康数据（取最近20条）
    health_data = (
        HltHealthData.query
        .filter_by(elderly_id=elderly_id)
        .order_by(HltHealthData.measure_time.desc())
        .limit(20)
        .all()
    )

    # 用药计划
    med_plans = HltMedicationPlan.query.filter_by(
        elderly_id=elderly_id, status=1
    ).all()

    # 最近告警
    recent_alerts = (
        SafAlert.query
        .filter_by(elderly_id=elderly_id)
        .order_by(SafAlert.alert_time.desc())
        .limit(5)
        .all()
    )

    # 最近订单
    recent_orders = (
        SvcOrder.query
        .filter_by(elderly_id=elderly_id)
        .order_by(SvcOrder.created_at.desc())
        .limit(5)
        .all()
    )

    # 订单详情预加载产品名（避免模板直接访问无relationship的o.product）
    order_product_ids = [o.product_id for o in recent_orders if o.product_id]
    product_map = {p.product_id: p.product_name for p in
                   db.session.query(SvcProduct).filter(SvcProduct.product_id.in_(order_product_ids)).all()
                   } if order_product_ids else {}

    return render_template('elderly_detail.html',
                           e=elderly,
                           elderly=elderly,
                           devices=devices,
                           family_binds=family_binds,
                           health_data=health_data,
                           med_plans=med_plans,
                           recent_alerts=recent_alerts,
                           recent_orders=recent_orders,
                           order_product_map=product_map,
                           gender_map=GENDER_MAP,
                           health_level_map=HEALTH_LEVEL_MAP,
                           living_status_map=LIVING_STATUS_MAP,
                           HEALTH_LEVEL_MAP=HEALTH_LEVEL_MAP,
                           LIVING_STATUS_MAP=LIVING_STATUS_MAP,
                           ALERT_TYPE_MAP=ALERT_TYPE_MAP,
                           ALERT_LEVEL_MAP=ALERT_LEVEL_MAP,
                           ALERT_STATUS_MAP=ALERT_STATUS_MAP,
                           ORDER_STATUS_MAP=ORDER_STATUS_MAP)


@elderly_bp.route('/elderly/<int:elderly_id>', methods=['PUT'])
def update_elderly(elderly_id):
    """更新老人信息"""
    elderly = UsrElderly.query.get_or_404(elderly_id)
    data = request.get_json()

    if not data:
        return jsonify({'code': -1, 'msg': '请求体不能为空'}), 400

    # 允许更新的字段
    updatable_fields = [
        'name', 'phone', 'address', 'living_status', 'health_level',
        'emergency_contact_name', 'emergency_contact_phone',
        'blood_type', 'allergies', 'medical_history', 'remark',
        'sos_enabled', 'privacy_mode',
    ]
    for field in updatable_fields:
        if field in data:
            setattr(elderly, field, data[field])

    db.session.commit()
    return jsonify({'code': 0, 'msg': '更新成功'})
