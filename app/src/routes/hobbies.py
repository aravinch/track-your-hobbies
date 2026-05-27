from flask import Blueprint, request, jsonify
from src import db
from src.models.hobby import Hobby


hobbies_bp = Blueprint("hobbies", __name__)


@hobbies_bp.route("/hobby", methods=["POST"])
def add_hobby():
    data = request.get_json()

    if not data.get("name") or not data.get("category"):
        return jsonify({"error": "name and category are required"}), 400

    hobby = Hobby(
        name=data["name"],
        category=data["category"],
        hours_spent=data.get("hours_spent", 0.0)
    )

    db.session.add(hobby)
    db.session.commit()

    return jsonify(hobby.to_dict()), 201


@hobbies_bp.route("/hobbies", methods=["GET"])
def get_hobbies():
    hobbies = Hobby.query.all()
    return jsonify([h.to_dict() for h in hobbies]), 200
