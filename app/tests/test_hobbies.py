import pytest
from src import create_app, db as _db


@pytest.fixture
def app():
    app = create_app()
    app.config["TESTING"] = True
    app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///:memory:"

    with app.app_context():
        _db.create_all()
        yield app
        _db.drop_all()


@pytest.fixture
def client(app):
    return app.test_client()


def test_get_hobbies_empty(client):
    response = client.get("/hobbies")
    assert response.status_code == 200
    assert response.json == []


def test_add_hobby(client):
    response = client.post("/hobby", json={
        "name": "Reading",
        "category": "Education",
        "hours_spent": 5
    })
    assert response.status_code == 201
    assert response.json["name"] == "Reading"


def test_dashboard(client):
    response = client.get("/dashboard")
    assert response.status_code == 200
    assert "total_hobbies" in response.json