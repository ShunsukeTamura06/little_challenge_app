from pydantic import BaseModel

class TaskReplaceRequest(BaseModel):
    new_task_id: str
    source: str
