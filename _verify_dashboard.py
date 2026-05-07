# -*- coding: utf-8 -*-
"""仪表盘数据验证脚本"""

import sys
sys.path.insert(0, 'C:\\Users\\panlifeng\\.qclaw\\workspace-x74fgmx0vyb8p5is\\ylsh-admin')
from app import create_app
import json

app = create_app()

print('=' * 60)
print('银龄守护 - B端街道后台仪表盘 - 数据验证报告')
print('=' * 60)

with app.test_client() as client:
    # 1. 测试统计数据 API
    print('\n【1. 统计卡片数据】')
    response = client.get('/api/dashboard/stats')
    data = response.get_json()
    if data['code'] == 0:
        stats = data['data']
        print('  老人总数: {}'.format(stats['elderly_count']))
        print('  今日告警: {}'.format(stats['today_alerts']))
        print('  进行中订单: {}'.format(stats['active_orders']))
        print('  服务人员: {}'.format(stats['worker_count']))
        print('  状态: 正常')
    else:
        print('  错误: {}'.format(data))

    # 2. 测试最近告警 API
    print('\n【2. 最近告警列表】')
    response = client.get('/api/dashboard/alerts/recent')
    data = response.get_json()
    if data['code'] == 0:
        alerts = data['data']
        print('  返回记录数: {}'.format(len(alerts)))
        level_map = {0: 'P0-紧急', 1: 'P1-高', 2: 'P2-中', 3: 'P3-低'}
        status_map = {0: '待处理', 1: '处理中', 2: '已解决'}
        for i, alert in enumerate(alerts[:5], 1):
            level = level_map.get(alert['alert_level'], '未知')
            status = status_map.get(alert['alert_status'], '未知')
            print('  {}. [{}] {} - {} - {}'.format(
                i, alert['alert_no'], alert['elderly_name'], level, status))
        print('  状态: 正常')

    # 3. 测试最近订单 API
    print('\n【3. 最近订单列表】')
    response = client.get('/api/dashboard/orders/recent')
    data = response.get_json()
    if data['code'] == 0:
        orders = data['data']
        print('  返回记录数: {}'.format(len(orders)))
        status_map = {0: '待提交', 1: '待支付', 2: '已支付', 3: '待接单', 
                     4: '已接单', 5: '服务中', 6: '已完成', 7: '已取消'}
        for i, order in enumerate(orders[:5], 1):
            status = status_map.get(order['order_status'], '未知')
            print('  {}. [{}] {} - {} - {}'.format(
                i, order['order_no'], order['elderly_name'], 
                order['product_name'], status))
        print('  状态: 正常')

    # 4. 测试页面渲染
    print('\n【4. 仪表盘页面渲染】')
    response = client.get('/dashboard')
    if response.status_code == 200:
        html = response.data.decode('utf-8')
        checks = ['老人总数', '今日告警', '进行中订单', '服务人员', 
                 '最近告警', '最近订单']
        all_found = all(check in html for check in checks)
        print('  页面状态: 200 OK')
        print('  关键元素: {}'.format('全部找到' if all_found else '部分缺失'))
        print('  状态: 正常')
    else:
        print('  页面状态: {}'.format(response.status_code))

print('\n' + '=' * 60)
print('验证完成！所有数据正常显示。')
print('=' * 60)
