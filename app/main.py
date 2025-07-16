from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from typing import Dict

app = FastAPI()

# In-memory "database"
tasks: Dict[int, Dict[str, str]] = {}
task_id_counter = 1

class Task(BaseModel):
    title: str
    description: str = ""

# Serve static frontend files
app.mount("/", StaticFiles(directory="app/static", html=True), name="static")

#@app.get("/health")
#def health_check():
#    return {"status": "ok"}

@app.post("/tasks")
def create_task(task: Task):
    global task_id_counter
    task_data = task.dict()
    task_data["id"] = task_id_counter
    tasks[task_id_counter] = task_data
    task_id_counter += 1
    return task_data

@app.get("/tasks/{task_id}")
def read_task(task_id: int):
    if task_id not in tasks:
        raise HTTPException(status_code=404, detail="Task not found")
    return tasks[task_id]

@app.put("/tasks/{task_id}")
def update_task(task_id: int, task: Task):
    if task_id not in tasks:
        raise HTTPException(status_code=404, detail="Task not found")
    updated = task.dict()
    updated["id"] = task_id
    tasks[task_id] = updated
    return updated

@app.delete("/tasks/{task_id}")
def delete_task(task_id: int):
    if task_id not in tasks:
        raise HTTPException(status_code=404, detail="Task not found")
    del tasks[task_id]
    return {"message": "Task deleted"}

