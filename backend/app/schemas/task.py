from pydantic import BaseModel
from typing import Optional

class TaskReplaceRequest(BaseModel):
    new_task_id: Optional[str] = None
    my_task_id: Optional[int] = None
    source: str
