# app/src/models/hobby.py
# This defines what a "hobby" looks like in the database
# Same concept as a MySQL table definition

from datetime import datetime
from src import db

class Hobby(db.Model):
    __tablename__ = "hobbies"

    id          = db.Column(db.Integer, primary_key=True)
    name        = db.Column(db.String(100), nullable=False)
    category    = db.Column(db.String(50), nullable=False)
    hours_spent = db.Column(db.Float, default=0.0)
    created_at  = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        # Converts database row to JSON-friendly dictionary
        return {
            "id":          self.id,
            "name":        self.name,
            "category":    self.category,
            "hours_spent": self.hours_spent,
            "created_at":  self.created_at.strftime("%Y-%m-%d %H:%M")
        }