-- =============================================================
-- CORTE 3 · Base de Datos Avanzadas · UP Chiapas
-- Archivo: 04_roles_y_permisos.sql
-- =============================================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'rol_veterinario') THEN
        CREATE ROLE rol_veterinario;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'rol_recepcion') THEN
        CREATE ROLE rol_recepcion;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'rol_admin') THEN
        CREATE ROLE rol_admin;
    END IF;

    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'vet_aut') THEN
        CREATE USER vet_aut WITH PASSWORD 'password1';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'vet_aura') THEN
        CREATE USER vet_aura WITH PASSWORD 'password2';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'vet_auro') THEN
        CREATE USER vet_auro WITH PASSWORD 'password3';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'usr_recepcion') THEN
        CREATE USER usr_recepcion WITH PASSWORD 'password4';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'usr_admin') THEN
        CREATE USER usr_admin WITH PASSWORD 'password5';
    END IF;
END $$;

GRANT rol_veterinario TO vet_aut, vet_aura, vet_auro;
GRANT rol_recepcion   TO usr_recepcion;
GRANT rol_admin       TO usr_admin;

REVOKE ALL ON ALL TABLES    IN SCHEMA public FROM rol_veterinario, rol_recepcion, rol_admin;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM rol_veterinario, rol_recepcion, rol_admin;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM rol_veterinario, rol_recepcion, rol_admin;

GRANT SELECT ON mascotas            TO rol_veterinario;
GRANT SELECT ON duenos              TO rol_veterinario;
GRANT SELECT ON citas               TO rol_veterinario;
GRANT SELECT ON vacunas_aplicadas   TO rol_veterinario;
GRANT SELECT ON inventario_vacunas  TO rol_veterinario;
GRANT SELECT ON vet_atiende_mascota TO rol_veterinario;

GRANT INSERT ON citas             TO rol_veterinario;
GRANT INSERT ON vacunas_aplicadas TO rol_veterinario;

GRANT USAGE ON SEQUENCE citas_id_seq             TO rol_veterinario;
GRANT USAGE ON SEQUENCE vacunas_aplicadas_id_seq TO rol_veterinario;

GRANT SELECT ON v_mascotas_con_dueno            TO rol_veterinario;
GRANT SELECT ON v_mascotas_vacunacion_pendiente TO rol_veterinario;

GRANT EXECUTE ON PROCEDURE sp_agendar_cita(INT, INT, TIMESTAMP, TEXT, INT) TO rol_veterinario;

GRANT SELECT ON mascotas            TO rol_recepcion;
GRANT SELECT ON duenos              TO rol_recepcion;
GRANT SELECT ON citas               TO rol_recepcion;
GRANT SELECT ON veterinarios        TO rol_recepcion;
GRANT SELECT ON vet_atiende_mascota TO rol_recepcion;

GRANT INSERT ON citas TO rol_recepcion;

GRANT USAGE ON SEQUENCE citas_id_seq TO rol_recepcion;

GRANT SELECT ON v_mascotas_con_dueno            TO rol_recepcion;
GRANT SELECT ON v_mascotas_vacunacion_pendiente TO rol_recepcion;

GRANT EXECUTE ON PROCEDURE sp_agendar_cita(INT, INT, TIMESTAMP, TEXT, INT) TO rol_recepcion;

GRANT ALL PRIVILEGES ON ALL TABLES    IN SCHEMA public TO rol_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO rol_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO rol_admin;
GRANT EXECUTE ON ALL ROUTINES         IN SCHEMA public TO rol_admin;
GRANT USAGE, CREATE ON SCHEMA public TO rol_admin;

GRANT CONNECT ON DATABASE clinica_vet TO rol_veterinario, rol_recepcion, rol_admin;
GRANT USAGE ON SCHEMA public          TO rol_veterinario, rol_recepcion, rol_admin;