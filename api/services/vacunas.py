import json
import time
import logging
from fastapi import HTTPException
from database import get_pool
from cache import get_redis
from schemas.vacunas import VacunaAplicarCreate

logger = logging.getLogger(__name__)

CACHE_KEY = "vacunacion_pendiente"
CACHE_TTL = 300 

async def _set_context(conn, rol: str, vet_id: int):
    await conn.execute(f"SET LOCAL ROLE {rol}")
    await conn.execute(
        "SELECT set_config('app.current_vet_id', $1, TRUE)",
        str(vet_id)
    )

async def pendientes(rol: str, vet_id: int):
    r = await get_redis()

    cached = await r.get(CACHE_KEY)
    if cached:
        logger.info("[CACHE HIT] vacunacion_pendiente — datos desde Redis")
        return json.loads(cached)

    logger.info("[CACHE MISS] vacunacion_pendiente — consultando PostgreSQL")
    t0 = time.monotonic()

    pool = await get_pool()
    async with pool.acquire() as conn:
        async with conn.transaction():
            await _set_context(conn, rol, vet_id)
            rows = await conn.fetch(
                "SELECT * FROM v_mascotas_vacunacion_pendiente"
            )

    elapsed = int((time.monotonic() - t0) * 1000)
    logger.info(f"[BD] vacunacion_pendiente completada en {elapsed}ms")

    result = [dict(r) for r in rows]
    for item in result:
        if item.get("ultima_vacuna"):
            item["ultima_vacuna"] = item["ultima_vacuna"].isoformat()

    await r.setex(CACHE_KEY, CACHE_TTL, json.dumps(result))
    logger.info(f"[CACHE SET] vacunacion_pendiente — TTL={CACHE_TTL}s")

    return result

async def aplicar(body: VacunaAplicarCreate, rol: str, vet_id: int):
    pool = await get_pool()
    async with pool.acquire() as conn:
        async with conn.transaction():
            await _set_context(conn, rol, vet_id)
            try:
                await conn.execute(
                    """
                    INSERT INTO vacunas_aplicadas
                        (mascota_id, vacuna_id, veterinario_id, fecha_aplicacion, costo_cobrado)
                    VALUES ($1, $2, $3, $4, $5)
                    """,
                    body.mascota_id,
                    body.vacuna_id,
                    vet_id,
                    body.fecha_aplicacion,
                    body.costo_cobrado
                )
            except Exception as e:
                logger.error(f"Error aplicar vacuna: {e}")
                raise HTTPException(status_code=400, detail=str(e))

    r = await get_redis()
    await r.delete(CACHE_KEY)
    logger.info("[CACHE INVALIDADO] vacunacion_pendiente — vacuna aplicada")

    return {"message": "Vacuna aplicada correctamente. Caché invalidado."}