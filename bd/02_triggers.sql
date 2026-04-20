-- =============================================================
-- CORTE 3 · Base de Datos Avanzadas · UP Chiapas
-- Archivo: 02_triggers.sql
-- =============================================================

CREATE OR REPLACE FUNCTION fn_registrar_historial_cita()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO historial_movimientos (tipo, referencia_id, descripcion, fecha)
    VALUES (
        'NUEVA_CITA',
        NEW.id,
        FORMAT(
            'Cita agendada: mascota_id=%s, veterinario_id=%s, fecha=%s, motivo=%s',
            NEW.mascota_id,
            NEW.veterinario_id,
            TO_CHAR(NEW.fecha_hora, 'DD/MM/YYYY HH24:MI'),
            COALESCE(NEW.motivo, 'Sin motivo especificado')
        ),
        NOW()
    );

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_historial_cita ON citas;

CREATE TRIGGER trg_historial_cita
    AFTER INSERT ON citas
    FOR EACH ROW
    EXECUTE FUNCTION fn_registrar_historial_cita();


CREATE OR REPLACE FUNCTION fn_actualizar_stock_vacuna()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_stock_actual  INT;
    v_stock_minimo  INT;
    v_nombre_vacuna VARCHAR(80);
BEGIN
    UPDATE inventario_vacunas
    SET stock_actual = stock_actual - 1
    WHERE id = NEW.vacuna_id
    RETURNING stock_actual, stock_minimo, nombre
    INTO v_stock_actual, v_stock_minimo, v_nombre_vacuna;

    IF v_stock_actual < v_stock_minimo THEN
        INSERT INTO alertas (tipo, descripcion, fecha)
        VALUES (
            'STOCK_BAJO',
            FORMAT(
                'ALERTA: Vacuna "%s" (id=%s) tiene stock bajo. Actual: %s, Mínimo: %s.',
                v_nombre_vacuna,
                NEW.vacuna_id,
                v_stock_actual,
                v_stock_minimo
            ),
            NOW()
        );
        RAISE NOTICE 'ALERTA STOCK BAJO: % tiene % unidades (mínimo: %)',
            v_nombre_vacuna, v_stock_actual, v_stock_minimo;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_alerta_stock_vacuna ON vacunas_aplicadas;

CREATE TRIGGER trg_alerta_stock_vacuna
    AFTER INSERT ON vacunas_aplicadas
    FOR EACH ROW
    EXECUTE FUNCTION fn_actualizar_stock_vacuna();
