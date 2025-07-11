# tests/test_main.py
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_create_task():
    response = client.post("/tasks", json={"title": "Buy milk", "description": "2% organic"})
    assert response.status_code == 200
    data = response.json()
    assert data["title"] == "Buy milk"
    assert "id" in data

def test_read_task_not_found():
    response = client.get("/tasks/999")
    assert response.status_code == 404

def test_update_task():
    # First create a task
    response = client.post("/tasks", json={"title": "Write code", "description": ""})
    task_id = response.json()["id"]

    # Now update it
    response = client.put(f"/tasks/{task_id}", json={"title": "Write better code", "description": "Refactor"})
    assert response.status_code == 200
    data = response.json()
    assert data["title"] == "Write better code"

def test_delete_task():
    response = client.post("/tasks", json={"title": "Temp task", "description": ""})
    task_id = response.json()["id"]

    # Delete it
    response = client.delete(f"/tasks/{task_id}")
    assert response.status_code == 200
    assert response.json()["message"] == "Task deleted"


