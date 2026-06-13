# app/src/__init__.py
# This is the app factory — creates and configures Flask

from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate

db = SQLAlchemy()
migrate = Migrate()  # ✅ NEW — create Migrate instance


def create_app():
    app = Flask(__name__)

    # Load config
    app.config.from_object("src.config.Config")

    # Initialise database
    db.init_app(app)
    migrate.init_app(app, db)    # ✅ NEW — initialise migrations

    # Register routes
    from src.routes.hobbies import hobbies_bp
    from src.routes.dashboard import dashboard_bp

    app.register_blueprint(hobbies_bp)
    app.register_blueprint(dashboard_bp)

    # Create tables if they don't exist
  #  with app.app_context():
   #     db.create_all()

    return app
