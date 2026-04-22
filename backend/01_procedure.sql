-- =============================================================
-- CORTE 3 · Base de Datos Avanzadas · UP Chiapas
-- Archivo: 01_procedures.sql
-- =============================================================

CREATE OR REPLACE PROCEDURE sp_agendar_cita(
    p_mascota_id     INT,
    p_veterinario_id INT,
    p_fecha_hora     TIMESTAMP,
    p_motivo         TEXT,
    OUT p_cita_id    INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_vet_activo     BOOLEAN;
    v_dias_descanso  VARCHAR(50);
    v_dia_semana     TEXT;
    v_conflicto      INT;
    v_mascota_existe INT;
BEGIN
    SELECT COUNT(*) INTO v_mascota_existe
    FROM mascotas
    WHERE id = p_mascota_id;

    IF v_mascota_existe = 0 THEN
        RAISE EXCEPTION 'La mascota con id % no existe.', p_mascota_id;
    END IF;

    SELECT activo, dias_descanso
    INTO v_vet_activo, v_dias_descanso
    FROM veterinarios
    WHERE id = p_veterinario_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El veterinario con id % no existe.', p_veterinario_id;
    END IF;

    IF NOT v_vet_activo THEN
        RAISE EXCEPTION 'El veterinario con id % está inactivo y no puede recibir citas.', p_veterinario_id;
    END IF;

    v_dia_semana := CASE EXTRACT(DOW FROM p_fecha_hora)
        WHEN 0 THEN 'domingo'
        WHEN 1 THEN 'lunes'
        WHEN 2 THEN 'martes'
        WHEN 3 THEN 'miércoles'
        WHEN 4 THEN 'jueves'
        WHEN 5 THEN 'viernes'
        WHEN 6 THEN 'sábado'
    END;

    IF v_dias_descanso <> '' AND v_dia_semana = ANY(string_to_array(v_dias_descanso, ',')) THEN
        RAISE EXCEPTION 'El veterinario descansa los %. No se puede agendar para el %.', 
            v_dias_descanso, TO_CHAR(p_fecha_hora, 'DD/MM/YYYY HH24:MI');
    END IF;

    SELECT COUNT(*) INTO v_conflicto
    FROM citas
    WHERE veterinario_id = p_veterinario_id
      AND fecha_hora = p_fecha_hora
      AND estado <> 'CANCELADA';

    IF v_conflicto > 0 THEN
        RAISE EXCEPTION 'El veterinario ya tiene una cita agendada el % a las %.', 
            TO_CHAR(p_fecha_hora, 'DD/MM/YYYY'), TO_CHAR(p_fecha_hora, 'HH24:MI');
    END IF;

    INSERT INTO citas (mascota_id, veterinario_id, fecha_hora, motivo, estado)
    VALUES (p_mascota_id, p_veterinario_id, p_fecha_hora, p_motivo, 'AGENDADA')
    RETURNING id INTO p_cita_id;

    RAISE NOTICE 'Cita agendada con éxito. ID de cita: %', p_cita_id;

EXCEPTION
WHEN OTHERS THEN
RAISE;
END;
$$;

CREATE OR REPLACE FUNCTION fn_total_facturado(
    p_mascota_id INT,
    p_anio       INT
)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_total NUMERIC(10, 2);
BEGIN
    SELECT COALESCE(SUM(costo), 0.00)
    INTO v_total
    FROM citas
    WHERE mascota_id = p_mascota_id
      AND EXTRACT(YEAR FROM fecha_hora) = p_anio
      AND estado = 'COMPLETADA';

    RETURN v_total;
END;
$$;
