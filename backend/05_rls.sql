-- =============================================================
-- CORTE 3 · Base de Datos Avanzadas · UP Chiapas
-- Archivo: 05_rls.sql
-- =============================================================

ALTER TABLE mascotas ENABLE ROW LEVEL SECURITY;
ALTER TABLE mascotas FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS pol_mascotas_veterinario ON mascotas;
DROP POLICY IF EXISTS pol_mascotas_recepcion   ON mascotas;
DROP POLICY IF EXISTS pol_mascotas_admin       ON mascotas;

CREATE POLICY pol_mascotas_veterinario ON mascotas
    FOR SELECT TO rol_veterinario
    USING (
        id IN (
            SELECT mascota_id FROM vet_atiende_mascota
            WHERE vet_id = NULLIF(current_setting('app.current_vet_id', TRUE), '')::INT
              AND activa = TRUE
        )
    );

CREATE POLICY pol_mascotas_recepcion ON mascotas
    FOR SELECT TO rol_recepcion
    USING (TRUE);

CREATE POLICY pol_mascotas_admin ON mascotas
    FOR ALL TO rol_admin
    USING (TRUE)
    WITH CHECK (TRUE);

ALTER TABLE citas ENABLE ROW LEVEL SECURITY;
ALTER TABLE citas FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS pol_citas_vet_select ON citas;
DROP POLICY IF EXISTS pol_citas_vet_insert ON citas;
DROP POLICY IF EXISTS pol_citas_recepcion  ON citas;
DROP POLICY IF EXISTS pol_citas_admin      ON citas;

CREATE POLICY pol_citas_vet_select ON citas
    FOR SELECT TO rol_veterinario
    USING (
        veterinario_id = NULLIF(current_setting('app.current_vet_id', TRUE), '')::INT
    );

CREATE POLICY pol_citas_vet_insert ON citas
    FOR INSERT TO rol_veterinario
    WITH CHECK (
        veterinario_id = NULLIF(current_setting('app.current_vet_id', TRUE), '')::INT
    );

CREATE POLICY pol_citas_recepcion ON citas
    FOR ALL TO rol_recepcion
    USING (TRUE)
    WITH CHECK (TRUE);

CREATE POLICY pol_citas_admin ON citas
    FOR ALL TO rol_admin
    USING (TRUE)
    WITH CHECK (TRUE);

ALTER TABLE vacunas_aplicadas ENABLE ROW LEVEL SECURITY;
ALTER TABLE vacunas_aplicadas FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS pol_vacunas_vet_select ON vacunas_aplicadas;
DROP POLICY IF EXISTS pol_vacunas_vet_insert ON vacunas_aplicadas;
DROP POLICY IF EXISTS pol_vacunas_admin      ON vacunas_aplicadas;

CREATE POLICY pol_vacunas_vet_select ON vacunas_aplicadas
    FOR SELECT TO rol_veterinario
    USING (
        mascota_id IN (
            SELECT mascota_id FROM vet_atiende_mascota
            WHERE vet_id = NULLIF(current_setting('app.current_vet_id', TRUE), '')::INT
              AND activa = TRUE
        )
    );

CREATE POLICY pol_vacunas_vet_insert ON vacunas_aplicadas
    FOR INSERT TO rol_veterinario
    WITH CHECK (
        mascota_id IN (
            SELECT mascota_id FROM vet_atiende_mascota
            WHERE vet_id = NULLIF(current_setting('app.current_vet_id', TRUE), '')::INT
              AND activa = TRUE
        )
    );

CREATE POLICY pol_vacunas_admin ON vacunas_aplicadas
    FOR ALL TO rol_admin
    USING (TRUE)
    WITH CHECK (TRUE);