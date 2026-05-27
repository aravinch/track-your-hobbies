# app/src/routes/dashboard.py
# Summary view — this becomes your dashboard

from flask import Blueprint, jsonify
from src.models.hobby import Hobby
from src import db
from sqlalchemy import func

dashboard_bp = Blueprint("dashboard", __name__)


# GET /dashboard — summary of all hobbies
@dashboard_bp.route("/dashboard", methods=["GET"])
def dashboard():
    total_hobbies = Hobby.query.count()
    total_hours = db.session.query(func.sum(Hobby.hours_spent)).scalar() or 0

    # Group by category
    categories = db.session.query(
        Hobby.category,
        func.count(Hobby.id).label("count"),
        func.sum(Hobby.hours_spent).label("hours")
    ).group_by(Hobby.category).all()

    return jsonify({
        "total_hobbies": total_hobbies,
        "total_hours":   round(total_hours, 1),
        "by_category": [
            {
                "category": c.category,
                "count":    c.count,
                "hours":    round(c.hours, 1)
            }
            for c in categories
        ]
    }), 200
