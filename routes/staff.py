# -*- coding: utf-8 -*-
"""人员管理路由 · 服务人员列表 / 详情 / 审核 / 转正"""

from flask import Blueprint, render_template, request, jsonify
from datetime import datetime
from models import db, UsrServiceWorker, SvcWorkerWallet, SvcOrder

staff_bp = Blueprint('staff', __name__)

# 人员类型映射
WORKER_TYPE_MAP = {
    1: '临时',
    2: '正式',
}

# 人员状态映射
WORKER_STATUS_MAP = {
    0: '待审核',
    1: '正常',
    2: '暂停',
    3: '禁用',
    4: '已注销',
}

# 订单状态映射
ORDER_STATUS_MAP = {0: '待支付', 1: '已支付', 2: '已接单', 3: '服务中', 4: '已完成', 5: '已取消', 6: '已退款', 7: '申诉中'}

# 告警状态映射
ALERT_STATUS_MAP = {0: '待处理', 1: '处理中', 2: '已解决', 3: '已忽略', 4: '误报'}

# 告警类型映射
ALERT_TYPE_MAP = {1: '摔倒', 2: '长时间无活动', 3: '离开安全区域', 4: '紧急求助', 5: '设备异常'}

# 告警等级映射
ALERT_LEVEL_MAP = {1: '低', 2: '中', 3: '高', 4: '紧急'}

# 健康等级映射
HEALTH_LEVEL_MAP = {1: '健康', 2: '基本健康', 3: '一般', 4: '较弱', 5: '虚弱'}


@staff_bp.route('/staff')
def staff_list():
    """服务人员列表 · 分页+按类型/状态筛选"""
    from sqlalchemy import func

    page = request.args.get('page', 1, type=int)
    worker_type = request.args.get('worker_type', type=int)
    worker_status = request.args.get('worker_status', type=int)

    query = UsrServiceWorker.query

    # 按类型筛选
    if worker_type is not None:
        query = query.filter(UsrServiceWorker.worker_type == worker_type)

    # 按状态筛选
    if worker_status is not None:
        query = query.filter(UsrServiceWorker.status == worker_status)

    query = query.order_by(UsrServiceWorker.created_at.desc())
    pagination = query.paginate(page=page, per_page=20, error_out=False)

    # 预计算各worker的订单统计数据（避免逐条查询）
    worker_ids = [w.worker_id for w in pagination.items]
    stats = {}
    if worker_ids:
        from sqlalchemy import case
        rows = db.session.query(
            SvcOrder.worker_id,
            func.count(SvcOrder.order_id).label('total'),
            func.sum(case((SvcOrder.order_status == 4, 1), else_=0)).label('completed'),
        ).filter(SvcOrder.worker_id.in_(worker_ids)).group_by(SvcOrder.worker_id).all()
        for r in rows:
            stats[r.worker_id] = {'total': r.total or 0, 'completed': r.completed or 0}

    workers = []
    for w in pagination.items:
        s = stats.get(w.worker_id, {'total': 0, 'completed': 0})
        workers.append({
            'worker_id': w.worker_id,
            'name': w.name,
            'phone': w.phone,
            'gender': '男' if w.gender == 1 else '女' if w.gender == 2 else '未知',
            'worker_type': w.worker_type,
            'worker_type_text': WORKER_TYPE_MAP.get(w.worker_type, f'类型{w.worker_type}'),
            'total_orders': s['total'],
            'completed_orders': s['completed'],
            'avg_rating': 0.0,  # UsrServiceWorker 无此字段
            'credit_score': 100,  # UsrServiceWorker 无此字段，默认100
            'status': w.status,
            'status_text': WORKER_STATUS_MAP.get(w.status, f'状态{w.status}'),
            'created_at': w.created_at.strftime('%Y-%m-%d') if w.created_at else '',
        })

    return render_template('staff.html',
                           workers=workers,
                           pagination=pagination,
                           current_type=worker_type,
                           current_status=worker_status,
                           worker_type_map=WORKER_TYPE_MAP,
                           worker_status_map=WORKER_STATUS_MAP)


@staff_bp.route('/staff/<int:worker_id>')
def staff_detail(worker_id):
    """人员详情 · 含钱包信息和服务统计"""
    worker = UsrServiceWorker.query.get_or_404(worker_id)

    # 钱包信息（可能无记录，优雅降级）
    from models import SvcWorkerWallet
    wallet = SvcWorkerWallet.query.filter_by(worker_id=worker_id).first()

    # 从订单表计算服务统计（避免模型字段缺失问题）
    total_orders = SvcOrder.query.filter_by(worker_id=worker_id).count()
    completed_orders = SvcOrder.query.filter_by(worker_id=worker_id, order_status=4).count()
    cancelled_orders = SvcOrder.query.filter_by(worker_id=worker_id, order_status=5).count()
    refund_orders = SvcOrder.query.filter_by(worker_id=worker_id, order_status=6).count()

    # 最近订单
    recent_orders = (
        SvcOrder.query
        .filter_by(worker_id=worker_id)
        .order_by(SvcOrder.created_at.desc())
        .limit(10)
        .all()
    )

    return render_template('staff_detail.html',
                           worker=worker,
                           wallet=wallet,
                           recent_orders=recent_orders,
                           worker_type_map=WORKER_TYPE_MAP,
                           worker_status_map=WORKER_STATUS_MAP,
                           order_status_map=ORDER_STATUS_MAP,
                           # 计算出的统计数据
                           total_orders=total_orders,
                           completed_orders=completed_orders,
                           cancelled_orders=cancelled_orders,
                           refund_orders=refund_orders,
                           avg_rating=worker.rating if hasattr(worker, 'rating') and worker.rating else None,
                           credit_score=None)


@staff_bp.route('/staff/<int:worker_id>/review', methods=['PUT'])
def review_worker(worker_id):
    """审核服务人员 · 通过或拒绝"""
    worker = UsrServiceWorker.query.get_or_404(worker_id)
    data = request.get_json()

    if not data or 'action' not in data:
        return jsonify({'code': -1, 'msg': '缺少 action 参数'}), 400

    action = data.get('action')  # 'approve' 或 'reject'
    remark = data.get('remark', '')

    if action == 'approve':
        worker.status = 1  # 正常
        worker.reviewed_at = datetime.now()
        worker.review_remark = remark or '审核通过'
    elif action == 'reject':
        worker.status = 3  # 禁用
        worker.reviewed_at = datetime.now()
        worker.review_remark = remark or '审核拒绝'
    else:
        return jsonify({'code': -1, 'msg': '无效的 action，应为 approve 或 reject'}), 400

    db.session.commit()
    return jsonify({'code': 0, 'msg': '审核完成'})


@staff_bp.route('/staff/<int:worker_id>/promote', methods=['PUT'])
def promote_worker(worker_id):
    """转正 · 临时→正式"""
    worker = UsrServiceWorker.query.get_or_404(worker_id)

    if worker.worker_type != 1:
        return jsonify({'code': -1, 'msg': '非临时人员无法转正'}), 400

    worker.worker_type = 2  # 正式
    worker.applied_formal_at = datetime.now()
    db.session.commit()

    return jsonify({'code': 0, 'msg': '转正成功'})
