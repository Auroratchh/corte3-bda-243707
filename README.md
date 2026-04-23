# corte3-bda-243707

**Base de Datos Avanzadas · Corte 3 · UP Chiapas · Abril 2026**

Sistema de clínica veterinaria con seguridad de BD: roles, RLS, Redis y hardening contra SQL Injection.

**Stack:** PostgreSQL 16 · Redis 7 · FastAPI + asyncpg · HTML/JS plano · Docker

---

## Cómo correr

```bash
# 1. Base de datos y Redis
docker compose up -d

# 2. API
cd api
python -m venv venv
.\venv\bin\Activate.ps1
pip install fastapi uvicorn asyncpg redis python-dotenv pydantic
uvicorn main:app --reload --port 8000

# 3. Frontend
cd frontend
python -m http.server 3000
# Abrir: http://localhost:3000/login.html
```

**`api/.env`**
```
DATABASE_URL=postgresql://postgres:postgres@localhost:5439/clinica_vet
REDIS_URL=redis://localhost:6379
```

---

## Decisiones de diseño

**1. ¿Qué política RLS aplicaste a `mascotas`?**

```sql
CREATE POLICY pol_mascotas_veterinario ON mascotas
    FOR SELECT TO rol_veterinario
    USING (
        id IN (
            SELECT mascota_id FROM vet_atiende_mascota
            WHERE vet_id = NULLIF(current_setting('app.current_vet_id', TRUE), '')::INT
              AND activa = TRUE
        )
    );
```

Cuando un veterinario hace SELECT en mascotas, PostgreSQL revisa fila por fila si esa mascota le pertenece según `vet_atiende_mascota`. Solo pasan las que están asignadas a ese vet. El backend le dice a PostgreSQL quién es con `set_config('app.current_vet_id', vet_id, TRUE)` al inicio de cada transacción.

---

**2. Vector de ataque en la identificación del veterinario y cómo se previene**

El `vet_id` llega en el header `x-vet-id` y alguien podría mandar el ID de otro veterinario. Pydantic valida que sea un entero positivo, y aunque mandaran un ID ajeno válido, la política RLS solo les mostraría las mascotas de ese ID, nunca acceso total a la tabla.

---

**3. SECURITY DEFINER**

No lo usé. Los procedures corren con los permisos del rol que los llama, y es suficiente porque cada rol tiene exactamente lo que necesita en `04_roles_y_permisos.sql`. Agregar `SECURITY DEFINER` sin necesidad hubiera introducido el vector de escalada por `search_path` que documenta PostgreSQL.

---

**4. TTL del caché Redis**

Elegí 300 segundos (5 minutos). La vista recorre todas las mascotas y vacunas, es cara. Con TTL muy corto el caché no sirve; con TTL muy largo un paciente recién vacunado seguiría apareciendo como pendiente. Por eso también invalido el caché manualmente con `redis.delete()` cada vez que se aplica una vacuna.

---

**5. Línea que previene SQL Injection**

`api/services/mascotas.py`, función `buscar()`:

```python
rows = await conn.fetch(
    "SELECT * FROM mascotas WHERE activo = TRUE AND nombre ILIKE $1 ORDER BY nombre",
    f"%{q}%"
)
```

El `$1` separa el SQL del input del usuario. asyncpg manda la query y el valor por separado, así que aunque el usuario mande `' OR '1'='1` o `'; DROP TABLE mascotas; --`, PostgreSQL lo recibe como texto a buscar, no como código.

---

**6. Qué se rompe si solo dejas SELECT en mascotas al veterinario**

1. Agendar citas — necesita INSERT en `citas` y EXECUTE en `sp_agendar_cita`, ambos fallarían.
2. Aplicar vacunas — necesita INSERT en `vacunas_aplicadas`, el endpoint fallaría y el caché nunca se invalidaría.
3. Ver vacunación pendiente — necesita SELECT en `v_mascotas_vacunacion_pendiente`, fallaría cuando el caché expire y el sistema intente refrescar desde BD.
