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