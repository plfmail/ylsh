# -*- coding: utf-8 -*-
"""银龄守护 · 街道管理后台 · Flask 应用入口"""

from flask import Flask, redirect, url_for, render_template
from config import Config
from models import db


def create_app(config_class=Config):
    """Flask 应用工厂函数"""
    app = Flask(__name__)
    app.config.from_object(config_class)

    # 初始化扩展
    db.init_app(app)

    # 注册蓝图
    from routes.dashboard import dashboard_bp
    from routes.alerts import alerts_bp
    from routes.elderly import elderly_bp
    from routes.services import services_bp
    from routes.staff import staff_bp

    app.register_blueprint(dashboard_bp)
    app.register_blueprint(alerts_bp)
    app.register_blueprint(elderly_bp)
    app.register_blueprint(services_bp)
    app.register_blueprint(staff_bp)

    # 首页重定向到仪表盘
    @app.route('/')
    def index():
        return redirect(url_for('dashboard.dashboard_page'))

    # 404 错误处理
    @app.errorhandler(404)
    def page_not_found(e):
        return render_template('404.html'), 404

    # 500 错误处理
    @app.errorhandler(500)
    def internal_error(e):
        return render_template('500.html'), 500

    return app


if __name__ == '__main__':
    app = create_app()
    app.run(debug=True, host='0.0.0.0', port=5000)
