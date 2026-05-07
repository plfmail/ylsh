# -*- coding: utf-8 -*-
"""服务管理路由 · 订单列表 / 详情 / 指派服务人员"""

from flask import Blueprint, render_template, request, jsonify
from datetime import datetime
from models import (
    db, SvcOrder, SvcOrderLog, SvcProduct,
    UsrElderly, UsrServiceWorker,
)

services_bp = Blueprint('services', __name__)

# 订单状态映射（与 seed 数据 order_status 枚举一致）
# 0=待支付 1=已支付 2=已接单 3=服务中 4=已完成 5=已取消 6=已退款 7=申诉中
ORDER_STATUS_MAP = {
    0: '待支付',
    1: '已支付',
    2: '已接单',
    3: '服务中',
    4: '已完成',
    5: '已取消',
    6: '已退款',
    7: '申诉中',
}

# 人员类型映射
WORKER_TYPE_MAP = {1: '临时', 2: '正式'}


@services_bp.route('/services')
def services_list():
    """订单列表 · 分页+按状态/日期筛选"""
    page = request.args.get('page', 1, type=int)
    order_status = request.args.get('order_status', type=int)
    date_from = request.args.get('date_from', '')
    date_to = request.args.get('date_to', '')

    query = SvcOrder.query

    # 按状态筛选
    if order_status is not None:
        query = query.filter(SvcOrder.order_status == order_status)

    # 按日期范围筛选
    if date_from:
        query = query.filter(SvcOrder.service_date >= date_from)
    if date_to:
        query = query.filter(SvcOrder.service_date <= date_to)

    query = query.order_by(SvcOrder.created_at.desc())
    pagination = query.paginate(page=page, per_page=20, error_out=False)

    orders = []
    for o in pagination.items:
        elderly = db.session.get(UsrElderly, o.elderly_id)
        product = db.session.get(SvcProduct, o.product_id)
        worker = db.session.get(UsrServiceWorker, o.worker_id) if o.worker_id else None

        orders.append({
            'order_id': o.order_id,
            'order_no': o.order_no,
            'elderly_name': elderly.name if elderly else '未知',
            'product_name': product.product_name if product else '未知',
            'worker_name': worker.name if worker else '未指派',
            'final_price': float(o.final_price) if o.final_price else 0,
            'order_status': o.order_status,
            'order_status_text': ORDER_STATUS_MAP.get(o.order_status, f'状态{o.order_status}'),
            'service_date': o.service_date.strftime('%Y-%m-%d') if o.service_date else '',
            'created_at': o.created_at.strftime('%Y-%m-%d %H:%M') if o.created_at else '',
        })

    return render_template('services.html',
                           orders=orders,
                           pagination=pagination,
                           current_status=order_status,
                           date_from=date_from,
                           date_to=date_to,
                           order_status_map=ORDER_STATUS_MAP)


@services_bp.route('/services/<int:order_id>')
def order_detail(order_id):
    """订单详情 · 含操作日志"""
    order = SvcOrder.query.get_or_404(order_id)

    # 关联信息
    elderly = db.session.get(UsrElderly, order.elderly_id)
    product = db.session.get(SvcProduct, order.product_id)
    worker = db.session.get(UsrServiceWorker, order.worker_id) if order.worker_id else None

    # 操作日志
    logs = (
        SvcOrderLog.query
        .filter_by(order_id=order_id)
        .order_by(SvcOrderLog.created_at.asc())
        .all()
    )

    return render_template('service_detail.html',
                           order=order,
                           elderly=elderly,
                           product=product,
                           worker=worker,
                           logs=logs,
                           order_status_map=ORDER_STATUS_MAP,
                           worker_type_map=WORKER_TYPE_MAP)


@services_bp.route('/services/<int:order_id>/assign', methods=['PUT'])
def assign_worker(order_id):
    """指派服务人员"""
    order = SvcOrder.query.get_or_404(order_id)
    data = request.get_json()

    if not data or 'worker_id' not in data:
        return jsonify({'code': -1, 'msg': '缺少 worker_id 参数'}), 400

    worker_id = data.get('worker_id')
    worker = UsrServiceWorker.query.get(worker_id)
    if not worker:
        return jsonify({'code': -1, 'msg': '服务人员不存在'}), 404

    # 记录原状态
    old_status = order.order_status

    # 更新订单
    order.worker_id = worker_id
    order.order_status = 4  # 已接单
    order.accepted_at = datetime.now()

    # 记录操作日志
    log = SvcOrderLog(
        order_id=order_id,
        action='assign_worker',
        from_status=old_status,
        to_status=4,
        remark=f'街道指派服务人员 {worker.name}(ID:{worker_id})',
    )
    db.session.add(log)
    db.session.commit()

    return jsonify({'code': 0, 'msg': '指派成功'})
