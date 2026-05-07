# -*- coding: utf-8 -*-
"""告警管理路由 · 街道端告警查看与处理"""

from flask import Blueprint, render_template, request, jsonify
from datetime import datetime
from models import db, SafAlert, UsrElderly

alerts_bp = Blueprint('alerts', __name__)

# 告警状态映射
ALERT_STATUS_MAP = {
    0: '待通知家属',
    1: '已通知家属',
    2: '家属已响应',
    3: '已升级街道',
    4: '街道已响应',
    5: '已呼叫120',
    6: '已处理',
    7: '已取消',
}

# 告警级别映射
ALERT_LEVEL_MAP = {
    0: 'P0-紧急',
    1: 'P1-高',
    2: 'P2-中',
    3: 'P3-低',
}

# 告警类型映射
ALERT_TYPE_MAP = {
    1: '跌倒检测',
    2: 'SOS呼叫',
    3: '长时间静止',
    4: '离开安全区域',
    5: '异常行为',
}


@alerts_bp.route('/alerts')
def alerts_list():
    """告警列表 · 支持分页+按级别/状态筛选"""
    page = request.args.get('page', 1, type=int)
    alert_level = request.args.get('alert_level', type=int)
    alert_status = request.args.get('alert_status', type=int)

    query = SafAlert.query

    # 按级别筛选
    if alert_level is not None:
        query = query.filter(SafAlert.alert_level == alert_level)

    # 按状态筛选
    if alert_status is not None:
        query = query.filter(SafAlert.alert_status == alert_status)

    # 按告警时间倒序
    query = query.order_by(SafAlert.alert_time.desc())
    pagination = query.paginate(page=page, per_page=20, error_out=False)

    alerts = []
    for a in pagination.items:
        elderly = db.session.get(UsrElderly, a.elderly_id)
        elderly_name = elderly.name if elderly else '未知'
        elderly_phone = elderly.phone if elderly else ''
        alerts.append({
            'alert_id': a.alert_id,
            'alert_no': a.alert_no,
            'elderly_name': elderly_name,
            'elderly_phone': elderly_phone,
            'alert_type': ALERT_TYPE_MAP.get(a.alert_type, f'类型{a.alert_type}'),
            'alert_level': a.alert_level,
            'alert_level_text': ALERT_LEVEL_MAP.get(a.alert_level, f'P{a.alert_level}'),
            'confidence': float(a.confidence) if a.confidence else 0,
            'alert_status': a.alert_status,
            'alert_status_text': ALERT_STATUS_MAP.get(a.alert_status, f'状态{a.alert_status}'),
            'alert_time': a.alert_time.strftime('%Y-%m-%d %H:%M:%S') if a.alert_time else '',
            'location_desc': a.location_desc or '',
        })

    return render_template('alerts.html',
                           alerts=alerts,
                           pagination=pagination,
                           current_level=alert_level,
                           current_status=alert_status,
                           alert_status_map=ALERT_STATUS_MAP,
                           alert_level_map=ALERT_LEVEL_MAP)


@alerts_bp.route('/alerts/<int:alert_id>')
def alert_detail(alert_id):
    """告警详情页"""
    alert = SafAlert.query.get_or_404(alert_id)
    return render_template('alert_detail.html', alert=alert,
                           alert_status_map=ALERT_STATUS_MAP,
                           alert_level_map=ALERT_LEVEL_MAP,
                           alert_type_map=ALERT_TYPE_MAP)


@alerts_bp.route('/alerts/<int:alert_id>/handle', methods=['PUT'])
def handle_alert(alert_id):
    """街道处理告警 · 更新 street_action / street_responded_at / alert_status"""
    alert = SafAlert.query.get_or_404(alert_id)
    data = request.get_json()

    if not data:
        return jsonify({'code': -1, 'msg': '请求体不能为空'}), 400

    # 街道处理动作（1=已处理 2=转120 3=误报关闭）
    street_action = data.get('street_action')
    remark = data.get('remark', '')

    if street_action is not None:
        alert.street_action = street_action
        alert.street_responded_at = datetime.now()

        # 根据动作自动更新告警状态
        if street_action == 1:
            alert.alert_status = 6  # 已处理
        elif street_action == 2:
            alert.alert_status = 5  # 已呼叫120
        elif street_action == 3:
            alert.alert_status = 7  # 已取消（误报）
            alert.cancel_reason = remark or '街道判定误报'

        if remark:
            alert.resolve_remark = remark

        if street_action in (1, 3):
            alert.resolved_at = datetime.now()

    db.session.commit()
    return jsonify({'code': 0, 'msg': '处理成功'})
