from pydantic import BaseModel
from typing import Literal

class LoginRequest(BaseModel):
    rol: Literal["rol_veterinario", "rol_recepcionista", "rol_administrador"]
    vet_id: int = 0

class LoginResponse(BaseModel):
    rol: str
    vet_id: int
    message: str