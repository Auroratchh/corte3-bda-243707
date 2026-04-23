import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from database import get_pool, close_pool
from cache import close_redis
from routers import mascotas, citas, vacunas, auth

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S"
)

@asynccontextmanager
async def lifespan(app: FastAPI):
    await get_pool()
    yield
    await close_pool()
    await close_redis()

app = FastAPI(
    title="Clínica Veterinaria — BDA Corte 3",
    description="API con seguridad de BD: RLS, roles, Redis, hardening SQL Injection",
    version="1.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://127.0.0.1:3000",
                   "http://localhost:5500", "http://127.0.0.1:5500"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router,     prefix="/auth",     tags=["Auth"])
app.include_router(mascotas.router, prefix="/mascotas", tags=["Mascotas"])
app.include_router(citas.router,    prefix="/citas",    tags=["Citas"])
app.include_router(vacunas.router,  prefix="/vacunas",  tags=["Vacunas"])

@app.get("/health", tags=["Health"])
async def health():
    return {"status": "ok"}