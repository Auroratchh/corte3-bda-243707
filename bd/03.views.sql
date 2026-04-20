-- =============================================================
-- CORTE 3 · Base de Datos Avanzadas · UP Chiapas
-- Archivo: 03_views.sql
-- =============================================================

CREATE OR REPLACE VIEW v_mascotas_vacunacion_pendiente AS
SELECT
    m.id                                    AS mascota_id,
    m.nombre                                AS mascota_nombre,
    m.especie,
    d.nombre                                AS dueno_nombre,
    d.telefono                              AS dueno_telefono,
    d.email                                 AS dueno_email,
    MAX(va.fecha_aplicacion)                AS ultima_vacuna,
    CASE
        WHEN MAX(va.fecha_aplicacion) IS NULL THEN 'NUNCA VACUNADA'
        ELSE 'VACUNA VENCIDA (más de 1 año)'
    END                                     AS motivo_pendiente,
    CURRENT_DATE - MAX(va.fecha_aplicacion) AS dias_sin_vacuna
FROM mascotas m
JOIN duenos d ON d.id = m.dueno_id
LEFT JOIN vacunas_aplicadas va ON va.mascota_id = m.id
GROUP BY m.id, m.nombre, m.especie, d.nombre, d.telefono, d.email
HAVING
    MAX(va.fecha_aplicacion) IS NULL
    OR MAX(va.fecha_aplicacion) < CURRENT_DATE - INTERVAL '1 year'
ORDER BY dias_sin_vacuna DESC NULLS FIRST;

CREATE OR REPLACE VIEW v_resumen_citas_veterinario AS
SELECT
    v.id                                     AS vet_id,
    v.nombre                                 AS veterinario,
    COUNT(c.id) FILTER (WHERE c.estado = 'COMPLETADA')  AS citas_completadas,
    COUNT(c.id) FILTER (WHERE c.estado = 'AGENDADA')    AS citas_agendadas,
    COUNT(c.id) FILTER (WHERE c.estado = 'CANCELADA')   AS citas_canceladas,
    COALESCE(SUM(c.costo) FILTER (WHERE c.estado = 'COMPLETADA'), 0) AS total_facturado
FROM veterinarios v
LEFT JOIN citas c ON c.veterinario_id = v.id
GROUP BY v.id, v.nombre
ORDER BY total_facturado DESC;

CREATE OR REPLACE VIEW v_mascotas_con_dueno AS
SELECT
    m.id            AS mascota_id,
    m.nombre        AS mascota_nombre,
    m.especie,
    m.fecha_nacimiento,
    DATE_PART('year', AGE(m.fecha_nacimiento))::INT AS edad_anios,
    d.id            AS dueno_id,
    d.nombre        AS dueno_nombre,
    d.telefono,
    d.email
FROM mascotas m
JOIN duenos d ON d.id = m.dueno_id
ORDER BY m.nombre;
