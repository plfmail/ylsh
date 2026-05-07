# -*- coding: utf-8 -*-
"""仪表盘路由 · 统计概览 + 最近动态"""

from flask import Blueprint, jsonify, render_template
from sqlalchemy import func
from datetime import date
from models import (
    db, UsrElderly, SafAlert, SvcOrder, UsrServiceWorker,
    CmmStatsSnapshot, SvcProduct,
)

dashboard_bp = Blueprint('dashboard', __name__)


@dashboard_bp.route('/dashboard')
def dashboard_page():
    """渲染仪表盘页面"""
    return render_template('dashboard.html')


@dashboard_bp.route('/api/dashboard/stats')
def dashboard_stats():
    """JSON API · 仪表盘统计数字"""
    try:
        # 老人总数
        elderly_count = db.session.query(func.count(UsrElderly.elderly_id)).scalar() or 0

        # 今日告警数
        today = date.today()
        today_alerts = db.session.query(func.count(SafAlert.alert_id)).filter(
            func.date(SafAlert.alert_time) == today
        ).scalar() or 0

        # 进行中订单数（状态 1=待支付 2=已支付 3=待接单 4=已接单 5=服务中）
        active_orders = db.session.query(func.count(SvcOrder.order_id)).filter(
            SvcOrder.order_status.in_([1, 2, 3, 4, 5])
        ).scalar() or 0

        # 服务人员总数
        worker_count = db.session.query(func.count(UsrServiceWorker.worker_id)).scalar() or 0

        return jsonify({
            'code': 0,
            'data': {
                'elderly_count': elderly_count,
                'today_alerts': today_alerts,
                'active_orders': active_orders,
                'worker_count': worker_count,
            }
        })
    except Exception as e:
        return jsonify({'code': -1, 'msg': str(e)}), 500


@dashboard_bp.route('/api/dashboard/alerts/recent')
def recent_alerts():
    """JSON API · 最近10条告警"""
    try:
        # Use manual join instead of relationship
        alerts = (
            db.session.query(SafAlert)
            .order_by(SafAlert.alert_time.desc())
            .limit(10)
            .all()
        )
        data = []
        for a in alerts:
            # Manual lookup for elderly name
            elderly_name = '未知'
            if a.elderly_id:
                elderly = db.session.get(UsrElderly, a.elderly_id)
                if elderly:
                    elderly_name = elderly.name
            
            data.append({
                'alert_id': a.alert_id,
                'alert_no': a.alert_no,
                'elderly_name': elderly_name,
                'alert_type': a.alert_type,
                'alert_level': a.alert_level,
                'alert_status': a.alert_status,
                'alert_time': a.alert_time.strftime('%Y-%m-%d %H:%M:%S') if a.alert_time else '',
            })
        return jsonify({'code': 0, 'data': data})
    except Exception as e:
        return jsonify({'code': -1, 'msg': str(e)}), 500


@dashboard_bp.route('/api/dashboard/orders/recent')
def recent_orders():
    """JSON API · 最近10条订单"""
    try:
        orders = (
            SvcOrder.query
            .order_by(SvcOrder.created_at.desc())
            .limit(10)
            .all()
        )
        data = []
        for o in orders:
            # Manual lookups
            elderly = db.session.get(UsrElderly, o.elderly_id)
            product = db.session.get(SvcProduct, o.product_id)
            worker = db.session.get(UsrServiceWorker, o.worker_id) if o.worker_id else None
            
            data.append({
                'order_id': o.order_id,
                'order_no': o.order_no,
                'elderly_name': elderly.name if elderly else '未知',
                'product_name': product.product_name if product else '未知',
                'worker_name': worker.name if worker else '未指派',
                'final_price': float(o.final_price) if o.final_price else 0,
                'order_status': o.order_status,
                'service_date': o.service_date.strftime('%Y-%m-%d') if o.service_date else '',
            })
        return jsonify({'code': 0, 'data': data})
    except Exception as e:
        return jsonify({'code': -1, 'msg': str(e)}), 500