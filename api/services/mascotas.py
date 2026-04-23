import logging
from fastapi import HTTPException
from database import get_pool
from schemas.mascotas import MascotaCreate

logger = logging.getLogger(__name__)

async def _set_context(conn, rol: str, vet_id: int):
    """
    Establece el rol de PostgreSQL y el vet_id de sesión para RLS.
    SET LOCAL ROLE limita los privilegios al rol correcto.
    set_config con TRUE (is_local) hace que el valor desaparezca al terminar la transacción.
    """
    await conn.execute(f"SET LOCAL ROLE {rol}")
    await conn.execute(
        "SELECT set_config('app.current_vet_id', $1, TRUE)",
        str(vet_id)
    )

async def listar(rol: str, vet_id: int):
    pool = await get_pool()
    async with pool.acquire() as conn:
        async with conn.transaction():
            await _set_context(conn, rol, vet_id)
            rows = await conn.fetch(
                "SELECT * FROM mascotas WHERE activo = TRUE ORDER BY nombre"
            )
    return [dict(r) for r in rows]

async def buscar(q: str, rol: str, vet_id: int):
    """
    HARDENING contra SQL Injection:
    El input del usuario se pasa como $1 — parámetro separado de la query.
    asyncpg envía query y valor en canales distintos del protocolo wire de PostgreSQL.
    Ningún carácter especial del input puede modificar la estructura del SQL.
    """
    pool = await get_pool()
    async with pool.acquire() as conn:
        async with conn.transaction():
            await _set_context(conn, rol, vet_id)
            rows = await conn.fetch(
                "SELECT * FROM mascotas WHERE activo = TRUE AND nombre ILIKE $1 ORDER BY nombre",
                f"%{q}%"   
            )
    return [dict(r) for r in rows]

async def registrar(body: MascotaCreate, rol: str, vet_id: int):
    pool = await get_pool()
    async with pool.acquire() as conn:
        async with conn.transaction():
            await _set_context(conn, rol, vet_id)
            try:
                row = await conn.fetchrow(
                    "CALL sp_registrar_mascota($1, $2, $3, $4, NULL)",
                    body.nombre, body.especie, body.fecha_nacimiento, body.dueno_id
                )
            except Exception as e:
                logger.error(f"Error registrar mascota: {e}")
                raise HTTPException(status_code=400, detail=str(e))
            mascota_id = row["p_mascota_id"]
            return await conn.fetchrow(
                "SELECT * FROM mascotas WHERE id = $1", mascota_id
            )

async def dar_baja(mascota_id: int, rol: str, vet_id: int):
    pool = await get_pool()
    async with pool.acquire() as conn:
        async with conn.transaction():
            await _set_context(conn, rol, vet_id)
            try:
                await conn.execute("CALL sp_dar_baja_mascota($1)", mascota_id)
            except Exception as e:
                logger.error(f"Error dar baja mascota: {e}")
                raise HTTPException(status_code=400, detail=str(e))
    return {"message": f"Mascota {mascota_id} dada de baja correctamente"}