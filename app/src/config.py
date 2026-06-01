# app/src/config.py
# Reads configuration from environment variables
# Never hardcode passwords — same lesson as .tfvars

import os


class Config:
    # Database connection — reads from environment variable
    SQLALCHEMY_DATABASE_URI = os.getenv(
        "DATABASE_URL",
        "sqlite:///hobbies.db"  # fallback for local dev
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SECRET_KEY = os.getenv("SECRET_KEY", "local-dev-key")
# ✅ ADD THESE — prevents connection timeout errors on Azure SQL
    SQLALCHEMY_ENGINE_OPTIONS = {
        "pool_pre_ping": True,       # tests connection before using it
        "pool_recycle": 1800,        # recycles connections every 30 mins

    }
    