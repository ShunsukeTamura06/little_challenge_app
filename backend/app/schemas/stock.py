from pydantic import BaseModel

class StockCreate(BaseModel):
    task_id: str

class StockResponse(BaseModel):
    id: str
    user_id: str
    challenge_id: int

    class Config:
        orm_mode = True
