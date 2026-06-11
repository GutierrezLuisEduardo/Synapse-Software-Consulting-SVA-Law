


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE SCHEMA IF NOT EXISTS "public";


ALTER SCHEMA "public" OWNER TO "pg_database_owner";


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE OR REPLACE FUNCTION "public"."calcular_puntaje_perfil"("p_perfil_id" integer) RETURNS numeric
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_enfoque   JSONB;
    v_puntaje   NUMERIC := 0;
    v_parcial   NUMERIC;
BEGIN
    -- Obtener el enfoque_riesgos de la sofom asociada al perfil
    SELECT s.enfoque_riesgos
      INTO v_enfoque
      FROM sofom s
      JOIN perfiles_cliente pc ON pc.sofom_id = s.sofom_id
     WHERE pc.perfiles_cliente_id = p_perfil_id;

    IF v_enfoque IS NULL THEN
        RETURN 0;
    END IF;

    -- ── Campos que almacenan `valores` directamente ──────────
    -- peso(catalogo_id) × valor_almacenado_en_cliente
    SELECT COALESCE(SUM(
               COALESCE((v_enfoque->>(t.cid::TEXT))::NUMERIC, 0)
               * COALESCE(t.val::NUMERIC, 0)
           ), 0)
      INTO v_parcial
      FROM perfiles_cliente pc
      JOIN clientes c ON c.cliente_id = pc.cliente_id
      JOIN LATERAL (VALUES
              (3,  c.pais_origen),
              (4,  c.nacionalidad),
              (5,  c.domicilio),
              (6,  c.vinculado_con_grupo),
              (9,  c.actividad_economica),
              (13, c.dependientes_economicos),
              (14, c.estado_civil),
              (15, c.numero_hijos),
              (16, c.tipo_vivienda),
              (17, c.nivel_estudios),
              (18, c.pertenece_partido_politico),
              (19, c.tipo_empleo),
              (20, c.ingresos_mensuales),
              (22, c.valor_patrimonio)
           ) AS t(cid, val) ON TRUE
     WHERE pc.perfiles_cliente_id = p_perfil_id;

    v_puntaje := v_puntaje + COALESCE(v_parcial, 0);

    -- ── Campos que almacenan `id_opcion` (inferidos) ────────
    -- peso(catalogo_id) × tf_catalogos.valores del id_opcion
    SELECT COALESCE(SUM(
               COALESCE((v_enfoque->>(tc.catalogo_id::TEXT))::NUMERIC, 0)
               * COALESCE(tc.valores::NUMERIC, 0)
           ), 0)
      INTO v_parcial
      FROM perfiles_cliente pc
      JOIN clientes c ON c.cliente_id = pc.cliente_id
      JOIN LATERAL (VALUES
              (c.peps),
              (c.edad),
              (c.senial_alerta_historica),
              (c.cambio_estatus)
           ) AS t(id_op) ON TRUE
      JOIN tf_catalogos tc ON tc.id_opcion = t.id_op
     WHERE pc.perfiles_cliente_id = p_perfil_id
       AND t.id_op IS NOT NULL;

    v_puntaje := v_puntaje + COALESCE(v_parcial, 0);

    RETURN ROUND(v_puntaje, 2);
END;
$$;


ALTER FUNCTION "public"."calcular_puntaje_perfil"("p_perfil_id" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_alerta_roi24_peps"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_cliente_id       INTEGER;
    v_razon_social     VARCHAR(120);
    v_sofom_id         SMALLINT;
    v_actualmente_peps BOOLEAN;
BEGIN
    SELECT pc.cliente_id,
           cl.razon_social,
           cl.sofom_id,
           cl.actualmente_peps
    INTO   v_cliente_id,
           v_razon_social,
           v_sofom_id,
           v_actualmente_peps
    FROM   contratos ct
    JOIN   perfiles_cliente pc ON pc.perfiles_cliente_id = ct.perfiles_cliente_id
    JOIN   clientes cl         ON cl.cliente_id          = pc.cliente_id
    WHERE  ct.contrato_id = NEW.contrato_id;

    IF v_actualmente_peps = TRUE THEN
        INSERT INTO alertas (
            operacion_id, sofom_id,
            tipo_reporte_id, tipo_alerta_id, descripcion
        ) VALUES (
            NEW.operacion_id,
            v_sofom_id,
            4,
            3,
            'Operación de cliente hallado en listas de bloqueo, (' ||
                v_razon_social || ': ' || v_cliente_id || ')'
        );
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."fn_alerta_roi24_peps"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_alerta_roi_perfil_inconsistente"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_anterior          operaciones%ROWTYPE;
    v_cliente_id        INTEGER;
    v_razon_social      VARCHAR(120);
    v_sofom_id          SMALLINT;
    v_perfil_cliente_id INTEGER;
    v_es_inconsistente  BOOLEAN := FALSE;
BEGIN
    SELECT *
    INTO   v_anterior
    FROM   operaciones
    WHERE  contrato_id  = NEW.contrato_id
      AND  operacion_id < NEW.operacion_id
    ORDER BY operacion_id DESC
    LIMIT  1;

    IF FOUND THEN
        IF NEW.origen_recursos               IS DISTINCT FROM v_anterior.origen_recursos               OR
           NEW.origen_operacion              IS DISTINCT FROM v_anterior.origen_operacion              OR
           NEW.destino_operacion             IS DISTINCT FROM v_anterior.destino_operacion             OR
           NEW.instrumento_monetario         IS DISTINCT FROM v_anterior.instrumento_monetario         OR
           NEW.incremento_monto_vs_anterior  IS DISTINCT FROM v_anterior.incremento_monto_vs_anterior  OR
           NEW.pago_excedido                 IS DISTINCT FROM v_anterior.pago_excedido                 OR
           NEW.monto                         IS DISTINCT FROM v_anterior.monto
        THEN
            v_es_inconsistente := TRUE;
        END IF;
    END IF;

    IF v_es_inconsistente THEN
        SELECT pc.perfiles_cliente_id,
               pc.cliente_id,
               cl.razon_social,
               cl.sofom_id
        INTO   v_perfil_cliente_id,
               v_cliente_id,
               v_razon_social,
               v_sofom_id
        FROM   contratos ct
        JOIN   perfiles_cliente pc ON pc.perfiles_cliente_id = ct.perfiles_cliente_id
        JOIN   clientes cl         ON cl.cliente_id          = pc.cliente_id
        WHERE  ct.contrato_id = NEW.contrato_id;

        INSERT INTO alertas (
            operacion_id, sofom_id,
            tipo_reporte_id, tipo_alerta_id, descripcion
        ) VALUES (
            NEW.operacion_id,
            v_sofom_id,
            2,
            3,
            'Características de operación no consistentes con perfil transaccional de cliente, (' ||
                v_razon_social || ': ' || v_cliente_id || ')'
        );

        UPDATE perfiles_cliente
        SET    ultimo_cambio = NOW()
        WHERE  perfiles_cliente_id = v_perfil_cliente_id;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."fn_alerta_roi_perfil_inconsistente"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_alerta_roip"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    IF NEW.tipo_reporte_id = 3 THEN
        INSERT INTO alertas (
            operacion_id, sofom_id,
            tipo_reporte_id, tipo_alerta_id, descripcion,
            reporte_id
        ) VALUES (
            NEW.operacion_id,
            NEW.sofom_id,
            3,
            3,
            'Se ha emitido un nuevo reporte de operaciones internas',
            NEW.reporte_id
        );
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."fn_alerta_roip"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_alerta_ror_moneda_extranjera"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_cliente_id   INTEGER;
    v_razon_social VARCHAR(120);
    v_sofom_id     SMALLINT;
BEGIN
    IF NEW.monto >= 7500 AND NEW.es_moneda_extranjera = TRUE THEN

        SELECT pc.cliente_id,
               cl.razon_social,
               cl.sofom_id
        INTO   v_cliente_id,
               v_razon_social,
               v_sofom_id
        FROM   contratos ct
        JOIN   perfiles_cliente pc ON pc.perfiles_cliente_id = ct.perfiles_cliente_id
        JOIN   clientes cl         ON cl.cliente_id          = pc.cliente_id
        WHERE  ct.contrato_id = NEW.contrato_id;

        INSERT INTO alertas (
            operacion_id, sofom_id,
            tipo_reporte_id, tipo_alerta_id, descripcion
        ) VALUES (
            NEW.operacion_id,
            v_sofom_id,
            1,
            3,
            'Operación con monto mayor a 7500 en moneda extranjera, (' ||
                v_razon_social || ': ' || v_cliente_id || ')'
        );
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."fn_alerta_ror_moneda_extranjera"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_job_alerta_dictamen_roi"() RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    INSERT INTO alertas (
        sofom_id,
        tipo_alerta_id,
        tipo_reporte_id,
        reporte_id,
        descripcion,
        fecha_hora_alerta
    )
    SELECT
        r.sofom_id,
        1,
        r.tipo_reporte_id,
        r.reporte_id,
        ta.descripcion || ' ' || tr.descripcion,
        NOW()
    FROM reportes r
    JOIN tf_tipos_alerta  ta ON ta.tipo_alerta_id  = 1
    JOIN tf_tipos_reporte tr ON tr.tipo_reporte_id = r.tipo_reporte_id
    WHERE r.tipo_reporte_id   = 2
      AND r.dictamen_emitido  = FALSE
      AND (r.plazo_dictamen - CURRENT_DATE) < 7;
END;
$$;


ALTER FUNCTION "public"."fn_job_alerta_dictamen_roi"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_job_alerta_dictamen_roip"() RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    -- Próximas fechas límite (17 ene/abr/jul/oct)
    v_proxima_fecha DATE;
    v_anio          INT := EXTRACT(YEAR FROM CURRENT_DATE)::INT;
    v_candidatas    DATE[];
    d               DATE;
BEGIN
    -- Construir las 4 fechas del año en curso y del siguiente
    v_candidatas := ARRAY[
        make_date(v_anio,     1,  17),
        make_date(v_anio,     4,  17),
        make_date(v_anio,     7,  17),
        make_date(v_anio,    10,  17),
        make_date(v_anio + 1, 1,  17)
    ];

    -- Obtener la próxima fecha >= hoy
    v_proxima_fecha := NULL;
    FOREACH d IN ARRAY v_candidatas LOOP
        IF d >= CURRENT_DATE THEN
            v_proxima_fecha := d;
            EXIT;
        END IF;
    END LOOP;

    IF v_proxima_fecha IS NULL THEN
        RETURN;
    END IF;

    -- Solo actuar si faltan menos de 7 días para esa fecha límite
    IF (v_proxima_fecha - CURRENT_DATE) >= 7 THEN
        RETURN;
    END IF;

    INSERT INTO alertas (
        sofom_id,
        tipo_alerta_id,
        tipo_reporte_id,
        reporte_id,
        descripcion,
        fecha_hora_alerta
    )
    SELECT
        r.sofom_id,
        1,
        r.tipo_reporte_id,
        r.reporte_id,
        ta.descripcion || ' ' || tr.descripcion,
        NOW()
    FROM reportes r
    JOIN tf_tipos_alerta  ta ON ta.tipo_alerta_id  = 1
    JOIN tf_tipos_reporte tr ON tr.tipo_reporte_id = r.tipo_reporte_id
    WHERE r.tipo_reporte_id  = 3
      AND r.dictamen_emitido = FALSE
      AND (r.plazo_dictamen - CURRENT_DATE) < 7;
END;
$$;


ALTER FUNCTION "public"."fn_job_alerta_dictamen_roip"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_job_alerta_entrega_roi"() RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    INSERT INTO alertas (
        sofom_id,
        tipo_alerta_id,
        tipo_reporte_id,
        reporte_id,
        descripcion,
        fecha_hora_alerta
    )
    SELECT
        r.sofom_id,
        2,
        r.tipo_reporte_id,
        r.reporte_id,
        ta.descripcion || ' ' || tr.descripcion,
        NOW()
    FROM reportes r
    JOIN tf_tipos_alerta  ta ON ta.tipo_alerta_id  = 2
    JOIN tf_tipos_reporte tr ON tr.tipo_reporte_id = r.tipo_reporte_id
    WHERE r.tipo_reporte_id    = 2
      AND r.ha_sido_descargado = FALSE;
END;
$$;


ALTER FUNCTION "public"."fn_job_alerta_entrega_roi"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_job_alerta_entrega_roi24"() RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    INSERT INTO alertas (
        sofom_id,
        tipo_alerta_id,
        tipo_reporte_id,
        reporte_id,
        descripcion,
        fecha_hora_alerta
    )
    SELECT
        r.sofom_id,
        2,
        r.tipo_reporte_id,
        r.reporte_id,
        ta.descripcion || ' ' || tr.descripcion,
        NOW()
    FROM reportes r
    JOIN tf_tipos_alerta  ta ON ta.tipo_alerta_id  = 2
    JOIN tf_tipos_reporte tr ON tr.tipo_reporte_id = r.tipo_reporte_id
    WHERE r.tipo_reporte_id    = 4
      AND r.ha_sido_descargado = FALSE;
END;
$$;


ALTER FUNCTION "public"."fn_job_alerta_entrega_roi24"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_job_alerta_entrega_roip"() RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    INSERT INTO alertas (
        sofom_id,
        tipo_alerta_id,
        tipo_reporte_id,
        reporte_id,
        descripcion,
        fecha_hora_alerta
    )
    SELECT
        r.sofom_id,
        2,
        r.tipo_reporte_id,
        r.reporte_id,
        ta.descripcion || ' ' || tr.descripcion,
        NOW()
    FROM reportes r
    JOIN tf_tipos_alerta  ta ON ta.tipo_alerta_id  = 2
    JOIN tf_tipos_reporte tr ON tr.tipo_reporte_id = r.tipo_reporte_id
    WHERE r.tipo_reporte_id    = 3
      AND r.ha_sido_descargado = FALSE;
END;
$$;


ALTER FUNCTION "public"."fn_job_alerta_entrega_roip"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_job_alerta_entrega_ror"() RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    INSERT INTO alertas (
        sofom_id,
        tipo_alerta_id,
        tipo_reporte_id,
        reporte_id,
        descripcion,
        fecha_hora_alerta
    )
    SELECT
        r.sofom_id,
        1,
        r.tipo_reporte_id,
        r.reporte_id,
        ta.descripcion || ' ' || tr.descripcion,
        NOW()
    FROM reportes r
    JOIN tf_tipos_alerta  ta ON ta.tipo_alerta_id  = 1
    JOIN tf_tipos_reporte tr ON tr.tipo_reporte_id = r.tipo_reporte_id
    WHERE r.tipo_reporte_id     = 1
      AND r.ha_sido_descargado  = FALSE;
END;
$$;


ALTER FUNCTION "public"."fn_job_alerta_entrega_ror"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_job_alerta_perfil_mensual"() RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    INSERT INTO alertas (sofom_id, tipo_alerta_id, descripcion, fecha_hora_alerta)
    SELECT
        c.sofom_id,
        4,
        c.cliente_id::TEXT
            || ' puede requerir una actualización de su perfil transaccional',
        NOW()
    FROM clientes c
    WHERE c.ha_actualizado_perfil = FALSE
      AND c.fecha_creacion <= NOW() - INTERVAL '6 months';
END;
$$;


ALTER FUNCTION "public"."fn_job_alerta_perfil_mensual"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_job_busqueda_listas_riesgo"() RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    rec           RECORD;
    v_nombre_norm TEXT;
    v_encontrado  BOOLEAN;
    v_lista       RECORD;
    v_peps_id     INT;
    v_senial_id   INT;
BEGIN
    FOR rec IN
        SELECT
            c.cliente_id,
            c.sofom_id,
            c.razon_social,
            pc.perfiles_cliente_id
        FROM perfiles_cliente pc
        JOIN clientes c ON c.cliente_id = pc.cliente_id
        WHERE (pc.ultima_revision IS NULL
               OR pc.ultima_revision < NOW() - INTERVAL '24 hours')
          AND pc.ultima_operacion IS NOT NULL
          AND pc.ultima_operacion > COALESCE(pc.ultima_revision, '-infinity'::TIMESTAMPTZ)
        ORDER BY pc.riesgo_final DESC
    LOOP
        v_nombre_norm := normalizar_texto(rec.razon_social);
        v_encontrado  := FALSE;
        v_peps_id     := NULL;

        -- Buscar nombre normalizado en todas las listas de la sofom
        FOR v_lista IN
            SELECT tipo, string_lista
            FROM listas_riesgo
            WHERE sofom_id = rec.sofom_id
        LOOP
            IF v_lista.string_lista LIKE ('%' || v_nombre_norm || '%') THEN
                v_encontrado := TRUE;

                -- Obtener id_opcion de PEPS según el tipo de lista (catalogo_id = 8)
                SELECT id_opcion INTO v_peps_id
                FROM tf_catalogos
                WHERE catalogo_id = 8
                  AND valores::NUMERIC = v_lista.tipo::NUMERIC
                LIMIT 1;

                EXIT; -- Con una coincidencia es suficiente
            END IF;
        END LOOP;

        IF v_encontrado THEN
            -- id_opcion de señal de alerta histórica (catalogo_id=26, valores=1 → con alerta)
            SELECT id_opcion INTO v_senial_id
            FROM tf_catalogos
            WHERE catalogo_id = 26
              AND valores::NUMERIC = 1
            LIMIT 1;

            UPDATE clientes SET
                peps                    = v_peps_id,
                estatus_alerta_historica = TRUE,
                ha_sido_peps            = TRUE,
                senial_alerta_historica  = v_senial_id,
                actualmente_peps        = TRUE
            WHERE cliente_id = rec.cliente_id;

        ELSE
            UPDATE clientes SET
                actualmente_peps = FALSE
            WHERE cliente_id = rec.cliente_id;
        END IF;

        -- Actualizar ultima_revision del perfil
        UPDATE perfiles_cliente
        SET ultima_revision = NOW()
        WHERE perfiles_cliente_id = rec.perfiles_cliente_id;

    END LOOP;
END;
$$;


ALTER FUNCTION "public"."fn_job_busqueda_listas_riesgo"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_job_calcular_riesgo_perfiles"() RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    rec         RECORD;
    v_nuevo_p   NUMERIC;
    v_nuevo_r   INT;
BEGIN
    FOR rec IN
        SELECT pc.perfiles_cliente_id
        FROM perfiles_cliente pc
        JOIN sofom s ON s.sofom_id = pc.sofom_id
        WHERE pc.ultimo_cambio IS NOT NULL
          AND (pc.ultima_revision IS NULL
               OR pc.ultimo_cambio > pc.ultima_revision)
          AND (s.ultima_revision IS NULL
               OR s.ultima_revision > COALESCE(pc.ultima_revision, '-infinity'::TIMESTAMPTZ))
    LOOP
        -- Calcular nuevo puntaje
        v_nuevo_p := calcular_puntaje_perfil(rec.perfiles_cliente_id);

        -- Determinar riesgo_final según umbrales documentados
        v_nuevo_r := CASE
                         WHEN v_nuevo_p <= 1.9 THEN 1
                         WHEN v_nuevo_p <= 2.5 THEN 2
                         ELSE 3
                     END;

        UPDATE perfiles_cliente
        SET puntaje        = v_nuevo_p,
            riesgo_final   = v_nuevo_r,
            ultima_revision = NOW()
        WHERE perfiles_cliente_id = rec.perfiles_cliente_id;

    END LOOP;
END;
$$;


ALTER FUNCTION "public"."fn_job_calcular_riesgo_perfiles"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_reporte_roi24"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_cliente_id   INTEGER;
    v_razon_social VARCHAR(120);
    v_tipo_entidad SMALLINT;
BEGIN
    IF NEW.tipo_alerta_id = 3 AND NEW.tipo_reporte_id = 4 THEN
        SELECT pc.cliente_id,
               cl.razon_social
        INTO   v_cliente_id,
               v_razon_social
        FROM   operaciones o
        JOIN   contratos ct        ON ct.contrato_id         = o.contrato_id
        JOIN   perfiles_cliente pc ON pc.perfiles_cliente_id = ct.perfiles_cliente_id
        JOIN   clientes cl         ON cl.cliente_id          = pc.cliente_id
        WHERE  o.operacion_id = NEW.operacion_id;

        v_tipo_entidad := fn_tipo_entidad_de_sofom(NEW.sofom_id);

        INSERT INTO reportes (
            tipo_reporte_id, operacion_id, tipo_entidad_id, sofom_id,
            asunto, descripcion
        ) VALUES (
            4,
            NEW.operacion_id,
            v_tipo_entidad,
            NEW.sofom_id,
            'Operación de cliente en listas de bloqueo',
            'El cliente ' || COALESCE(v_razon_social, '') ||
            ' (' || COALESCE(v_cliente_id::TEXT, '') || ')'
        );
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."fn_reporte_roi24"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_reporte_roi_aprobado"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_tipo_entidad SMALLINT;
BEGIN
    IF NEW.tipo_alerta_id  = 3
       AND NEW.tipo_reporte_id = 2
       AND OLD.esta_aprobado   = FALSE
       AND NEW.esta_aprobado   = TRUE
    THEN
        v_tipo_entidad := fn_tipo_entidad_de_sofom(NEW.sofom_id);

        INSERT INTO reportes (
            tipo_reporte_id, operacion_id, tipo_entidad_id, sofom_id,
            asunto, descripcion
        ) VALUES (
            2,
            NEW.operacion_id,
            v_tipo_entidad,
            NEW.sofom_id,
            'Operación incongruente con perfil transaccional',
            'La operación no concuerda con el perfil transaccional del cliente'
        );
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."fn_reporte_roi_aprobado"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_reporte_ror"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_tipo_entidad SMALLINT;
BEGIN
    IF NEW.tipo_alerta_id = 3 AND NEW.tipo_reporte_id = 1 THEN
        v_tipo_entidad := fn_tipo_entidad_de_sofom(NEW.sofom_id);

        INSERT INTO reportes (
            tipo_reporte_id, operacion_id, tipo_entidad_id, sofom_id,
            asunto, descripcion
        ) VALUES (
            1,
            NEW.operacion_id,
            v_tipo_entidad,
            NEW.sofom_id,
            'Operación relevante',
            'El monto de la operación ' || NEW.operacion_id ||
            ', alcanzó los 7500 en moneda extranjera'
        );
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."fn_reporte_ror"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_set_campos_cliente"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_anios         INTEGER;
    v_edad_opcion   SMALLINT;
    v_peps_tipo     SMALLINT;
    v_cambio_opcion SMALLINT;
    v_senial_opcion SMALLINT;
    v_peps_opcion   SMALLINT;
BEGIN
    -- ── Edad ─────────────────────────────────────────────────
    -- Busca la opción cuyo umbral (edad) sea <= años del cliente
    -- y sea el más cercano por arriba → usa índice parcial idx_tfc_edad.
    IF NEW.fecha_nacimiento IS NOT NULL
       AND NEW.id_tipo_persona = 0          -- solo persona física
    THEN
        v_anios := DATE_PART('year', AGE(CURRENT_DATE, NEW.fecha_nacimiento))::INTEGER;

        SELECT id_opcion
        INTO   v_edad_opcion
        FROM   tf_catalogos
        WHERE  edad IS NOT NULL
          AND  edad <= v_anios
        ORDER BY edad DESC
        LIMIT  1;

        -- Si no hay umbral <= edad (cliente muy joven), tomar el mínimo
        IF v_edad_opcion IS NULL THEN
            SELECT id_opcion
            INTO   v_edad_opcion
            FROM   tf_catalogos
            WHERE  edad IS NOT NULL
            ORDER BY edad ASC
            LIMIT  1;
        END IF;

        NEW.edad := v_edad_opcion;
    END IF;

    -- ── peps / cambio_estatus / senial_alerta_historica ──────
    -- Un solo escaneo (sobre filas NOT NULL de cada columna,
    -- que son poquísimas) obtiene los tres valores a la vez.
    v_peps_tipo := CASE WHEN NEW.actualmente_peps THEN 1 ELSE 4 END;

    SELECT
        MAX(id_opcion) FILTER (WHERE tipo_peps             = v_peps_tipo)           AS p,
        MAX(id_opcion) FILTER (WHERE cambio_listas_peps    = FALSE)                 AS c,
        MAX(id_opcion) FILTER (WHERE senial_alerta_historica = NEW.estatus_alerta_historica) AS s
    INTO v_peps_opcion, v_cambio_opcion, v_senial_opcion
    FROM tf_catalogos
    WHERE tipo_peps IS NOT NULL
       OR cambio_listas_peps IS NOT NULL
       OR senial_alerta_historica IS NOT NULL;

    IF v_peps_opcion   IS NOT NULL THEN NEW.peps                  := v_peps_opcion;   END IF;
    IF v_cambio_opcion IS NOT NULL THEN NEW.cambio_estatus         := v_cambio_opcion; END IF;
    IF v_senial_opcion IS NOT NULL THEN NEW.senial_alerta_historica := v_senial_opcion; END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."fn_set_campos_cliente"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_set_campos_contrato"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_catalogo_id            INTEGER;
    v_frecuencia_valor       NUMERIC(18,6);
    v_liquidacion_opcion     SMALLINT;
BEGIN
    -- Obtener catalogo_id y frecuencia del id_opcion = frecuencia_pago
    -- en un solo hit por PK (idx primario sobre id_opcion).
    SELECT catalogo_id, frecuencia
    INTO   v_catalogo_id, v_frecuencia_valor
    FROM   tf_catalogos
    WHERE  id_opcion = NEW.frecuencia_pago;

    IF v_frecuencia_valor IS NOT NULL THEN
        NEW.frecuencia := v_frecuencia_valor::SMALLINT;
    END IF;

    -- Buscar la primera opción de liquidacion_anticipada dentro del
    -- mismo catálogo → índice parcial idx_tfc_liquidacion_anticipada.
    IF v_catalogo_id IS NOT NULL THEN
        SELECT id_opcion
        INTO   v_liquidacion_opcion
        FROM   tf_catalogos
        WHERE  catalogo_id           = v_catalogo_id
          AND  liquidacion_anticipada IS NOT NULL
        ORDER BY liquidacion_anticipada ASC
        LIMIT  1;

        IF v_liquidacion_opcion IS NOT NULL THEN
            NEW.liquidacion_anticipada_ultimo_pago := v_liquidacion_opcion;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."fn_set_campos_contrato"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_set_campos_operacion"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_monto_anterior     NUMERIC(14,2);
    v_pago_por_operacion NUMERIC(14,2);
    v_hubo_incremento    BOOLEAN;
    v_pago_excedido      BOOLEAN;
    v_incr_opcion        SMALLINT;
    v_pago_opcion        SMALLINT;
BEGIN
    -- ── Monto anterior y pago_por_operacion ──────────────────
    -- Dos hits por PK/índice; no tocan tf_catalogos.
    SELECT monto
    INTO   v_monto_anterior
    FROM   operaciones
    WHERE  contrato_id = NEW.contrato_id
    ORDER BY operacion_id DESC
    LIMIT  1;

    SELECT pago_por_operacion
    INTO   v_pago_por_operacion
    FROM   contratos
    WHERE  contrato_id = NEW.contrato_id;

    v_hubo_incremento := (v_monto_anterior IS NOT NULL AND NEW.monto > v_monto_anterior);
    v_pago_excedido   := (v_pago_por_operacion IS NOT NULL
                          AND v_pago_por_operacion > 0
                          AND NEW.monto > v_pago_por_operacion);

    -- ── Un solo SELECT sobre tf_catalogos ────────────────────
    -- Filtra filas NOT NULL de cada columna (subconjunto pequeño)
    -- y extrae ambas opciones en una pasada.
    SELECT
        MAX(id_opcion) FILTER (WHERE incremento_vs_monto_anterior = v_hubo_incremento) AS inc,
        MAX(id_opcion) FILTER (
            WHERE pago_excedido IS NOT NULL
              AND (CASE WHEN v_pago_excedido
                        THEN pago_excedido > 0
                        ELSE pago_excedido = 0 OR pago_excedido IS NULL
                   END)
        ) AS pag
    INTO v_incr_opcion, v_pago_opcion
    FROM tf_catalogos
    WHERE incremento_vs_monto_anterior IS NOT NULL
       OR pago_excedido IS NOT NULL;

    IF v_incr_opcion IS NOT NULL THEN NEW.incremento_monto_vs_anterior := v_incr_opcion; END IF;
    IF v_pago_opcion IS NOT NULL THEN NEW.pago_excedido                 := v_pago_opcion; END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."fn_set_campos_operacion"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_set_plazo_dictamen"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_dias SMALLINT;
BEGIN
    SELECT dias_hasta_dictamen
    INTO   v_dias
    FROM   tf_tipos_reporte
    WHERE  tipo_reporte_id = NEW.tipo_reporte_id;

    IF v_dias IS NOT NULL THEN
        NEW.plazo_dictamen := (NEW.fecha_generacion + (v_dias || ' days')::INTERVAL)::DATE;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."fn_set_plazo_dictamen"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_tipo_entidad_de_sofom"("p_sofom_id" smallint) RETURNS smallint
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_tipo SMALLINT;
BEGIN
    SELECT tipo_entidad_id INTO v_tipo
    FROM   sofom
    WHERE  sofom_id = p_sofom_id;
    RETURN v_tipo;
END;
$$;


ALTER FUNCTION "public"."fn_tipo_entidad_de_sofom"("p_sofom_id" smallint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."normalizar_texto"("p_texto" "text") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $$
    SELECT lower(
               regexp_replace(
                   unaccent(p_texto),
                   '[^a-z ]', '', 'g'
               )
           );
$$;


ALTER FUNCTION "public"."normalizar_texto"("p_texto" "text") OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."alertas" (
    "alerta_id" integer NOT NULL,
    "regla_id" integer,
    "operacion_id" integer,
    "sofom_id" smallint NOT NULL,
    "tipo_reporte_id" smallint NOT NULL,
    "tipo_alerta_id" smallint NOT NULL,
    "estado_revision" boolean DEFAULT false NOT NULL,
    "fecha_hora_alerta" timestamp with time zone DEFAULT "now"() NOT NULL,
    "esta_aprobado" boolean DEFAULT false NOT NULL,
    "descripcion" "text" DEFAULT 'Sin descripción'::"text",
    "reporte_id" integer
);


ALTER TABLE "public"."alertas" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."alertas_alerta_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."alertas_alerta_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."alertas_alerta_id_seq" OWNED BY "public"."alertas"."alerta_id";



CREATE TABLE IF NOT EXISTS "public"."clientes" (
    "cliente_id" integer NOT NULL,
    "sofom_id" smallint NOT NULL,
    "razon_social" character varying(120) NOT NULL,
    "telefono" character varying(20) NOT NULL,
    "correo_electronico" character varying(100) NOT NULL,
    "clabe" character varying(18) NOT NULL,
    "serie_efirma" character varying(40) NOT NULL,
    "geolocalizacion" character varying(25) NOT NULL,
    "estatus_alerta_historica" boolean DEFAULT false NOT NULL,
    "ha_sido_peps" boolean DEFAULT false NOT NULL,
    "fecha_creacion" timestamp with time zone DEFAULT "now"() NOT NULL,
    "id_tipo_persona" smallint DEFAULT 0 NOT NULL,
    "curp" character varying(18),
    "rfc" character varying(15),
    "genero" character varying(20),
    "fecha_nacimiento" "date",
    "pais_nacimiento" character varying(80),
    "entidad_federativa_nacimiento" character varying(100),
    "nombre_apoderado_legal" character varying(120),
    "fecha_constitucion" "date",
    "pais_origen" smallint NOT NULL,
    "nacionalidad" smallint NOT NULL,
    "domicilio" smallint NOT NULL,
    "actividad_economica" smallint NOT NULL,
    "vinculado_con_grupo" smallint NOT NULL,
    "estado_civil" smallint NOT NULL,
    "dependientes_economicos" smallint NOT NULL,
    "numero_hijos" smallint NOT NULL,
    "nivel_estudios" smallint NOT NULL,
    "tipo_vivienda" smallint NOT NULL,
    "tipo_empleo" smallint NOT NULL,
    "ingresos_mensuales" smallint NOT NULL,
    "valor_patrimonio" smallint NOT NULL,
    "pertenece_partido_politico" smallint NOT NULL,
    "peps" smallint,
    "edad" smallint,
    "cambio_estatus" smallint,
    "senial_alerta_historica" smallint,
    "ha_actualizado_perfil" boolean DEFAULT false NOT NULL,
    "id_lista_hallado" smallint,
    "actualmente_peps" boolean DEFAULT false
);


ALTER TABLE "public"."clientes" OWNER TO "postgres";


COMMENT ON COLUMN "public"."clientes"."id_lista_hallado" IS 'id de lista de riesgo en que fue hallado';



CREATE SEQUENCE IF NOT EXISTS "public"."clientes_cliente_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."clientes_cliente_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."clientes_cliente_id_seq" OWNED BY "public"."clientes"."cliente_id";



CREATE TABLE IF NOT EXISTS "public"."contratos" (
    "contrato_id" integer NOT NULL,
    "perfiles_cliente_id" integer NOT NULL,
    "sofom_id" smallint NOT NULL,
    "id_ultima_operacion" smallint,
    "descripcion" character varying(150),
    "canal" smallint NOT NULL,
    "producto" smallint NOT NULL,
    "finalidad_credito" smallint NOT NULL,
    "frecuencia_pago" smallint NOT NULL,
    "frecuencia" smallint NOT NULL,
    "numero_pagos_acordados" smallint NOT NULL,
    "numero_pagos_hechos" smallint NOT NULL,
    "liquidacion_anticipada_ultimo_pago" smallint NOT NULL,
    "fecha_inicio" "date",
    "fecha_finalizacion" "date",
    "monto_total_pago" numeric(14,2) DEFAULT 0.0 NOT NULL,
    "monto_pagado" numeric(14,2) DEFAULT 0.0,
    "pago_por_operacion" numeric(14,2) DEFAULT 0.0
);


ALTER TABLE "public"."contratos" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."contratos_contrato_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."contratos_contrato_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."contratos_contrato_id_seq" OWNED BY "public"."contratos"."contrato_id";



CREATE TABLE IF NOT EXISTS "public"."criterios" (
    "criterio_id" integer NOT NULL,
    "id_catalogo" smallint NOT NULL,
    "id_operador" smallint NOT NULL,
    "id_opcion" smallint NOT NULL
);


ALTER TABLE "public"."criterios" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."criterios_criterio_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."criterios_criterio_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."criterios_criterio_id_seq" OWNED BY "public"."criterios"."criterio_id";



CREATE TABLE IF NOT EXISTS "public"."documentos" (
    "documento_id" integer NOT NULL,
    "sofom_id" smallint NOT NULL,
    "perfiles_cliente_id" integer NOT NULL,
    "tipo_documento_id" smallint NOT NULL,
    "referencia_archivo" character varying(200) NOT NULL,
    "fecha_carga" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."documentos" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."documentos_documento_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."documentos_documento_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."documentos_documento_id_seq" OWNED BY "public"."documentos"."documento_id";



CREATE TABLE IF NOT EXISTS "public"."listas_riesgo" (
    "lista_id" smallint NOT NULL,
    "sofom_id" smallint NOT NULL,
    "tipo" smallint NOT NULL,
    "string_lista" "text" NOT NULL,
    "ultima_actualizacion" "date" DEFAULT "now"()
);


ALTER TABLE "public"."listas_riesgo" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."listas_riesgo_lista_id_seq"
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."listas_riesgo_lista_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."listas_riesgo_lista_id_seq" OWNED BY "public"."listas_riesgo"."lista_id";



CREATE TABLE IF NOT EXISTS "public"."logs_auditoria" (
    "id_accion" integer NOT NULL,
    "sofom_id" smallint NOT NULL,
    "id_usuario" smallint NOT NULL,
    "id_tipo_accion" smallint NOT NULL,
    "hora_accion" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."logs_auditoria" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."logs_auditoria_id_accion_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."logs_auditoria_id_accion_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."logs_auditoria_id_accion_seq" OWNED BY "public"."logs_auditoria"."id_accion";



CREATE TABLE IF NOT EXISTS "public"."operaciones" (
    "operacion_id" integer NOT NULL,
    "contrato_id" integer NOT NULL,
    "origen_recursos" smallint NOT NULL,
    "origen_operacion" smallint NOT NULL,
    "destino_operacion" smallint NOT NULL,
    "instrumento_monetario" smallint NOT NULL,
    "incremento_monto_vs_anterior" smallint DEFAULT 0 NOT NULL,
    "pago_excedido" smallint DEFAULT 0 NOT NULL,
    "monto" numeric(14,2) DEFAULT 0.0 NOT NULL,
    "emision_operacion" timestamp with time zone DEFAULT "now"() NOT NULL,
    "mayor_a_7500_usd" boolean,
    "es_moneda_extranjera" boolean DEFAULT false NOT NULL
);


ALTER TABLE "public"."operaciones" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."operaciones_operacion_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."operaciones_operacion_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."operaciones_operacion_id_seq" OWNED BY "public"."operaciones"."operacion_id";



CREATE TABLE IF NOT EXISTS "public"."perfiles_cliente" (
    "perfiles_cliente_id" integer NOT NULL,
    "cliente_id" integer NOT NULL,
    "sofom_id" smallint NOT NULL,
    "prioridad" smallint DEFAULT 0 NOT NULL,
    "ultima_revision" timestamp with time zone,
    "operaciones_en_cola" integer DEFAULT 0 NOT NULL,
    "puntaje" numeric(4,2) DEFAULT 0 NOT NULL,
    "clasif_monitoreo" numeric(4,2) DEFAULT 0.0 NOT NULL,
    "clasif_cliente" numeric(4,2) DEFAULT 0.0 NOT NULL,
    "riesgo_final" smallint GENERATED ALWAYS AS (
CASE
    WHEN ("puntaje" <= 1.9) THEN 1
    WHEN ("puntaje" <= 2.5) THEN 2
    ELSE 3
END) STORED NOT NULL,
    "ultima_operacion" timestamp with time zone,
    "ultimo_cambio" timestamp with time zone
);


ALTER TABLE "public"."perfiles_cliente" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."perfiles_cliente_perfiles_cliente_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."perfiles_cliente_perfiles_cliente_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."perfiles_cliente_perfiles_cliente_id_seq" OWNED BY "public"."perfiles_cliente"."perfiles_cliente_id";



CREATE TABLE IF NOT EXISTS "public"."regla_criterios" (
    "regla_id" smallint NOT NULL,
    "criterio_id" smallint NOT NULL,
    "orden" smallint DEFAULT 1
);


ALTER TABLE "public"."regla_criterios" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."reglas" (
    "regla_id" smallint NOT NULL,
    "tipo_regla_id" smallint NOT NULL,
    "tipo_reporte_id" smallint NOT NULL,
    "tipo_entidad_id" smallint NOT NULL,
    "sofom_id" smallint NOT NULL,
    "fecha_inicio" timestamp with time zone NOT NULL,
    "periodicidad" smallint NOT NULL,
    "periodo_en_dias" boolean DEFAULT false NOT NULL,
    "ultima_revision" timestamp with time zone NOT NULL,
    "proxima_revision" timestamp with time zone NOT NULL
);


ALTER TABLE "public"."reglas" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."reglas_regla_id_seq"
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."reglas_regla_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."reglas_regla_id_seq" OWNED BY "public"."reglas"."regla_id";



CREATE TABLE IF NOT EXISTS "public"."reportes" (
    "reporte_id" integer NOT NULL,
    "tipo_reporte_id" smallint NOT NULL,
    "operacion_id" integer,
    "tipo_entidad_id" smallint NOT NULL,
    "sofom_id" smallint NOT NULL,
    "fecha_generacion" timestamp with time zone DEFAULT "now"() NOT NULL,
    "dictamen" character varying(400),
    "plazo_dictamen" "date",
    "ha_sido_descargado" boolean DEFAULT false NOT NULL,
    "dictamen_emitido" boolean DEFAULT false NOT NULL,
    "asunto" "text" DEFAULT 'Sin asunto'::"text" NOT NULL,
    "descripcion" "text" DEFAULT 'Sin descripción'::"text" NOT NULL,
    "evidencia" "text" DEFAULT ''::"text"
);


ALTER TABLE "public"."reportes" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."reportes_reporte_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."reportes_reporte_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."reportes_reporte_id_seq" OWNED BY "public"."reportes"."reporte_id";



CREATE TABLE IF NOT EXISTS "public"."roles" (
    "rol_id" smallint NOT NULL,
    "descripcion" character varying(70) NOT NULL
);


ALTER TABLE "public"."roles" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."roles_rol_id_seq"
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."roles_rol_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."roles_rol_id_seq" OWNED BY "public"."roles"."rol_id";



CREATE TABLE IF NOT EXISTS "public"."session" (
    "sid" character varying NOT NULL,
    "sess" json NOT NULL,
    "expire" timestamp(6) without time zone NOT NULL
);


ALTER TABLE "public"."session" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."sofom" (
    "sofom_id" smallint NOT NULL,
    "tipo_entidad_id" smallint NOT NULL,
    "razon_social" character varying(150) NOT NULL,
    "canal_privado" character varying(150),
    "estatus" boolean DEFAULT true NOT NULL,
    "fecha_creacion" timestamp with time zone DEFAULT "now"() NOT NULL,
    "enfoque_riesgos" "jsonb" DEFAULT '{"1": 0.1, "2": 0.1, "3": 0.2, "4": 0.2, "5": 0.2, "6": 0.2, "7": 0.2, "8": 0.1, "9": 0.4, "10": 0.1, "11": 0.2, "12": 0.1, "13": 0.1, "14": 0, "15": 0, "16": 0, "17": 0, "18": 0, "19": 0, "20": 0, "21": 0, "22": 0, "23": 0, "24": 0, "25": 0.2, "26": 0.3, "27": 0.2, "28": 0.1, "29": 0.1, "30": 0.4, "31": 0.1}'::"jsonb" NOT NULL,
    "ultima_revision" timestamp with time zone
);


ALTER TABLE "public"."sofom" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."sofom_sofom_id_seq"
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."sofom_sofom_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."sofom_sofom_id_seq" OWNED BY "public"."sofom"."sofom_id";



CREATE TABLE IF NOT EXISTS "public"."tf_catalogos" (
    "id_opcion" integer NOT NULL,
    "catalogo_id" integer,
    "opciones" character varying(255),
    "valores" integer,
    "tipo_id" integer,
    "clasificacion_id" integer,
    "frecuencia_de_pago_acordada" numeric(18,6),
    "frecuencia" numeric(18,6),
    "liquidacion_anticipada" numeric(18,6),
    "pago_excedido" numeric(18,6),
    "incremento_vs_monto_anterior" boolean,
    "senial_alerta_historica" boolean,
    "cambio_listas_peps" boolean,
    "tipo_peps" smallint,
    "edad" smallint
);


ALTER TABLE "public"."tf_catalogos" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."tf_catalogos_id_opcion_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."tf_catalogos_id_opcion_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."tf_catalogos_id_opcion_seq" OWNED BY "public"."tf_catalogos"."id_opcion";



CREATE TABLE IF NOT EXISTS "public"."tf_clasificaciones" (
    "clasificacion_id" smallint NOT NULL,
    "descripcion" character varying(255)
);


ALTER TABLE "public"."tf_clasificaciones" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tf_criterios_ebr" (
    "id" smallint NOT NULL,
    "catalogo_id" integer,
    "descripcion" character varying(255),
    "tipo_id" integer,
    "clasificacion_id" integer
);


ALTER TABLE "public"."tf_criterios_ebr" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tf_operadores" (
    "id_operador" smallint NOT NULL,
    "operador" character varying(5),
    "descripcion" character varying(25)
);


ALTER TABLE "public"."tf_operadores" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."tf_operadores_id_operador_seq"
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."tf_operadores_id_operador_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."tf_operadores_id_operador_seq" OWNED BY "public"."tf_operadores"."id_operador";



CREATE TABLE IF NOT EXISTS "public"."tf_tipos" (
    "tipo_id" smallint NOT NULL,
    "descripcion" character varying(255)
);


ALTER TABLE "public"."tf_tipos" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tf_tipos_acciones" (
    "id_tipo_accion" smallint NOT NULL,
    "descripcion" character varying(50)
);


ALTER TABLE "public"."tf_tipos_acciones" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."tf_tipos_acciones_id_tipo_accion_seq"
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."tf_tipos_acciones_id_tipo_accion_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."tf_tipos_acciones_id_tipo_accion_seq" OWNED BY "public"."tf_tipos_acciones"."id_tipo_accion";



CREATE TABLE IF NOT EXISTS "public"."tf_tipos_alerta" (
    "tipo_alerta_id" smallint NOT NULL,
    "descripcion" character varying(70) NOT NULL
);


ALTER TABLE "public"."tf_tipos_alerta" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."tf_tipos_alerta_tipo_alerta_id_seq"
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."tf_tipos_alerta_tipo_alerta_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."tf_tipos_alerta_tipo_alerta_id_seq" OWNED BY "public"."tf_tipos_alerta"."tipo_alerta_id";



CREATE TABLE IF NOT EXISTS "public"."tf_tipos_documento" (
    "tipo_documento_id" smallint NOT NULL,
    "descripcion" character varying(200) NOT NULL,
    "tipo_persona_id" smallint NOT NULL
);


ALTER TABLE "public"."tf_tipos_documento" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."tf_tipos_documento_tipo_documento_id_seq"
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."tf_tipos_documento_tipo_documento_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."tf_tipos_documento_tipo_documento_id_seq" OWNED BY "public"."tf_tipos_documento"."tipo_documento_id";



CREATE TABLE IF NOT EXISTS "public"."tf_tipos_entidad" (
    "tipo_entidad_id" smallint NOT NULL,
    "descripcion" character varying(50) NOT NULL
);


ALTER TABLE "public"."tf_tipos_entidad" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."tf_tipos_entidad_tipo_entidad_id_seq"
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."tf_tipos_entidad_tipo_entidad_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."tf_tipos_entidad_tipo_entidad_id_seq" OWNED BY "public"."tf_tipos_entidad"."tipo_entidad_id";



CREATE TABLE IF NOT EXISTS "public"."tf_tipos_origen" (
    "id" smallint NOT NULL,
    "descripcion" character varying NOT NULL
);


ALTER TABLE "public"."tf_tipos_origen" OWNER TO "postgres";


ALTER TABLE "public"."tf_tipos_origen" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."tf_tipos_origen_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."tf_tipos_persona" (
    "tipo_persona_id" smallint NOT NULL,
    "descripcion" character varying(25) NOT NULL
);


ALTER TABLE "public"."tf_tipos_persona" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."tf_tipos_persona_tipo_persona_id_seq"
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."tf_tipos_persona_tipo_persona_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."tf_tipos_persona_tipo_persona_id_seq" OWNED BY "public"."tf_tipos_persona"."tipo_persona_id";



CREATE TABLE IF NOT EXISTS "public"."tf_tipos_regla" (
    "tipo_regla_id" smallint NOT NULL,
    "descripcion" character varying(70) NOT NULL
);


ALTER TABLE "public"."tf_tipos_regla" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."tf_tipos_regla_tipo_regla_id_seq"
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."tf_tipos_regla_tipo_regla_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."tf_tipos_regla_tipo_regla_id_seq" OWNED BY "public"."tf_tipos_regla"."tipo_regla_id";



CREATE TABLE IF NOT EXISTS "public"."tf_tipos_reporte" (
    "tipo_reporte_id" smallint NOT NULL,
    "descripcion" character varying(50) NOT NULL,
    "requiere_dictamen" boolean NOT NULL,
    "dias_hasta_dictamen" smallint NOT NULL
);


ALTER TABLE "public"."tf_tipos_reporte" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."tf_tipos_reporte_tipo_reporte_id_seq"
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."tf_tipos_reporte_tipo_reporte_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."tf_tipos_reporte_tipo_reporte_id_seq" OWNED BY "public"."tf_tipos_reporte"."tipo_reporte_id";



CREATE TABLE IF NOT EXISTS "public"."usuarios" (
    "usuario_id" integer NOT NULL,
    "rol_id" smallint NOT NULL,
    "sofom_id" smallint,
    "nombre" character varying(120) NOT NULL,
    "correo_electronico" character varying(100) NOT NULL,
    "contrasena" character varying(255) NOT NULL,
    "fecha_creacion" timestamp with time zone DEFAULT "now"() NOT NULL,
    "ultimo_acceso" timestamp with time zone,
    "estatus" boolean DEFAULT true NOT NULL
);


ALTER TABLE "public"."usuarios" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."usuarios_usuario_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."usuarios_usuario_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."usuarios_usuario_id_seq" OWNED BY "public"."usuarios"."usuario_id";



ALTER TABLE ONLY "public"."alertas" ALTER COLUMN "alerta_id" SET DEFAULT "nextval"('"public"."alertas_alerta_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."clientes" ALTER COLUMN "cliente_id" SET DEFAULT "nextval"('"public"."clientes_cliente_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."contratos" ALTER COLUMN "contrato_id" SET DEFAULT "nextval"('"public"."contratos_contrato_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."criterios" ALTER COLUMN "criterio_id" SET DEFAULT "nextval"('"public"."criterios_criterio_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."documentos" ALTER COLUMN "documento_id" SET DEFAULT "nextval"('"public"."documentos_documento_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."listas_riesgo" ALTER COLUMN "lista_id" SET DEFAULT "nextval"('"public"."listas_riesgo_lista_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."logs_auditoria" ALTER COLUMN "id_accion" SET DEFAULT "nextval"('"public"."logs_auditoria_id_accion_seq"'::"regclass");



ALTER TABLE ONLY "public"."operaciones" ALTER COLUMN "operacion_id" SET DEFAULT "nextval"('"public"."operaciones_operacion_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."perfiles_cliente" ALTER COLUMN "perfiles_cliente_id" SET DEFAULT "nextval"('"public"."perfiles_cliente_perfiles_cliente_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."reglas" ALTER COLUMN "regla_id" SET DEFAULT "nextval"('"public"."reglas_regla_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."reportes" ALTER COLUMN "reporte_id" SET DEFAULT "nextval"('"public"."reportes_reporte_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."roles" ALTER COLUMN "rol_id" SET DEFAULT "nextval"('"public"."roles_rol_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."sofom" ALTER COLUMN "sofom_id" SET DEFAULT "nextval"('"public"."sofom_sofom_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."tf_catalogos" ALTER COLUMN "id_opcion" SET DEFAULT "nextval"('"public"."tf_catalogos_id_opcion_seq"'::"regclass");



ALTER TABLE ONLY "public"."tf_operadores" ALTER COLUMN "id_operador" SET DEFAULT "nextval"('"public"."tf_operadores_id_operador_seq"'::"regclass");



ALTER TABLE ONLY "public"."tf_tipos_acciones" ALTER COLUMN "id_tipo_accion" SET DEFAULT "nextval"('"public"."tf_tipos_acciones_id_tipo_accion_seq"'::"regclass");



ALTER TABLE ONLY "public"."tf_tipos_alerta" ALTER COLUMN "tipo_alerta_id" SET DEFAULT "nextval"('"public"."tf_tipos_alerta_tipo_alerta_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."tf_tipos_documento" ALTER COLUMN "tipo_documento_id" SET DEFAULT "nextval"('"public"."tf_tipos_documento_tipo_documento_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."tf_tipos_entidad" ALTER COLUMN "tipo_entidad_id" SET DEFAULT "nextval"('"public"."tf_tipos_entidad_tipo_entidad_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."tf_tipos_persona" ALTER COLUMN "tipo_persona_id" SET DEFAULT "nextval"('"public"."tf_tipos_persona_tipo_persona_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."tf_tipos_regla" ALTER COLUMN "tipo_regla_id" SET DEFAULT "nextval"('"public"."tf_tipos_regla_tipo_regla_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."tf_tipos_reporte" ALTER COLUMN "tipo_reporte_id" SET DEFAULT "nextval"('"public"."tf_tipos_reporte_tipo_reporte_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."usuarios" ALTER COLUMN "usuario_id" SET DEFAULT "nextval"('"public"."usuarios_usuario_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."alertas"
    ADD CONSTRAINT "alertas_pkey" PRIMARY KEY ("alerta_id");



ALTER TABLE ONLY "public"."clientes"
    ADD CONSTRAINT "clientes_pkey" PRIMARY KEY ("cliente_id");



ALTER TABLE ONLY "public"."contratos"
    ADD CONSTRAINT "contratos_pkey" PRIMARY KEY ("contrato_id");



ALTER TABLE ONLY "public"."criterios"
    ADD CONSTRAINT "criterios_id_catalogo_id_operador_id_opcion_key" UNIQUE ("id_catalogo", "id_operador", "id_opcion");



ALTER TABLE ONLY "public"."criterios"
    ADD CONSTRAINT "criterios_pkey" PRIMARY KEY ("criterio_id");



ALTER TABLE ONLY "public"."documentos"
    ADD CONSTRAINT "documentos_pkey" PRIMARY KEY ("documento_id");



ALTER TABLE ONLY "public"."listas_riesgo"
    ADD CONSTRAINT "listas_riesgo_pkey" PRIMARY KEY ("lista_id");



ALTER TABLE ONLY "public"."logs_auditoria"
    ADD CONSTRAINT "logs_auditoria_pkey" PRIMARY KEY ("id_accion");



ALTER TABLE ONLY "public"."operaciones"
    ADD CONSTRAINT "operaciones_pkey" PRIMARY KEY ("operacion_id");



ALTER TABLE ONLY "public"."perfiles_cliente"
    ADD CONSTRAINT "perfiles_cliente_pkey" PRIMARY KEY ("perfiles_cliente_id");



ALTER TABLE ONLY "public"."regla_criterios"
    ADD CONSTRAINT "regla_criterios_pkey" PRIMARY KEY ("regla_id", "criterio_id");



ALTER TABLE ONLY "public"."reglas"
    ADD CONSTRAINT "reglas_pkey" PRIMARY KEY ("regla_id");



ALTER TABLE ONLY "public"."reportes"
    ADD CONSTRAINT "reportes_pkey" PRIMARY KEY ("reporte_id");



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_descripcion_key" UNIQUE ("descripcion");



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_pkey" PRIMARY KEY ("rol_id");



ALTER TABLE ONLY "public"."session"
    ADD CONSTRAINT "session_pkey" PRIMARY KEY ("sid");



ALTER TABLE ONLY "public"."sofom"
    ADD CONSTRAINT "sofom_pkey" PRIMARY KEY ("sofom_id");



ALTER TABLE ONLY "public"."tf_catalogos"
    ADD CONSTRAINT "tf_catalogos_pkey" PRIMARY KEY ("id_opcion");



ALTER TABLE ONLY "public"."tf_clasificaciones"
    ADD CONSTRAINT "tf_clasificaciones_pkey" PRIMARY KEY ("clasificacion_id");



ALTER TABLE ONLY "public"."tf_criterios_ebr"
    ADD CONSTRAINT "tf_criterios_ebr_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."tf_operadores"
    ADD CONSTRAINT "tf_operadores_pkey" PRIMARY KEY ("id_operador");



ALTER TABLE ONLY "public"."tf_tipos_acciones"
    ADD CONSTRAINT "tf_tipos_acciones_pkey" PRIMARY KEY ("id_tipo_accion");



ALTER TABLE ONLY "public"."tf_tipos_alerta"
    ADD CONSTRAINT "tf_tipos_alerta_descripcion_key" UNIQUE ("descripcion");



ALTER TABLE ONLY "public"."tf_tipos_alerta"
    ADD CONSTRAINT "tf_tipos_alerta_pkey" PRIMARY KEY ("tipo_alerta_id");



ALTER TABLE ONLY "public"."tf_tipos_documento"
    ADD CONSTRAINT "tf_tipos_documento_descripcion_key" UNIQUE ("descripcion");



ALTER TABLE ONLY "public"."tf_tipos_documento"
    ADD CONSTRAINT "tf_tipos_documento_pkey" PRIMARY KEY ("tipo_documento_id");



ALTER TABLE ONLY "public"."tf_tipos_entidad"
    ADD CONSTRAINT "tf_tipos_entidad_descripcion_key" UNIQUE ("descripcion");



ALTER TABLE ONLY "public"."tf_tipos_entidad"
    ADD CONSTRAINT "tf_tipos_entidad_pkey" PRIMARY KEY ("tipo_entidad_id");



ALTER TABLE ONLY "public"."tf_tipos_origen"
    ADD CONSTRAINT "tf_tipos_origen_descripcion_key" UNIQUE ("descripcion");



ALTER TABLE ONLY "public"."tf_tipos_origen"
    ADD CONSTRAINT "tf_tipos_origen_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."tf_tipos_persona"
    ADD CONSTRAINT "tf_tipos_persona_descripcion_key" UNIQUE ("descripcion");



ALTER TABLE ONLY "public"."tf_tipos_persona"
    ADD CONSTRAINT "tf_tipos_persona_pkey" PRIMARY KEY ("tipo_persona_id");



ALTER TABLE ONLY "public"."tf_tipos"
    ADD CONSTRAINT "tf_tipos_pkey" PRIMARY KEY ("tipo_id");



ALTER TABLE ONLY "public"."tf_tipos_regla"
    ADD CONSTRAINT "tf_tipos_regla_descripcion_key" UNIQUE ("descripcion");



ALTER TABLE ONLY "public"."tf_tipos_regla"
    ADD CONSTRAINT "tf_tipos_regla_pkey" PRIMARY KEY ("tipo_regla_id");



ALTER TABLE ONLY "public"."tf_tipos_reporte"
    ADD CONSTRAINT "tf_tipos_reporte_pkey" PRIMARY KEY ("tipo_reporte_id");



ALTER TABLE ONLY "public"."usuarios"
    ADD CONSTRAINT "usuarios_correo_electronico_key" UNIQUE ("correo_electronico");



ALTER TABLE ONLY "public"."usuarios"
    ADD CONSTRAINT "usuarios_pkey" PRIMARY KEY ("usuario_id");



CREATE INDEX "IDX_session_expire" ON "public"."session" USING "btree" ("expire");



CREATE INDEX "idx_alertas_operacion_id" ON "public"."alertas" USING "btree" ("operacion_id");



CREATE INDEX "idx_alertas_sofom_id" ON "public"."alertas" USING "btree" ("sofom_id");



CREATE INDEX "idx_contratos_perfiles_cliente_id" ON "public"."contratos" USING "btree" ("perfiles_cliente_id");



CREATE INDEX "idx_documentos_perfiles_cliente_id" ON "public"."documentos" USING "btree" ("perfiles_cliente_id");



CREATE INDEX "idx_operaciones_contrato_id" ON "public"."operaciones" USING "btree" ("contrato_id");



CREATE INDEX "idx_perfiles_cliente_cliente_id" ON "public"."perfiles_cliente" USING "btree" ("cliente_id");



CREATE INDEX "idx_tfc_cambio_listas_peps" ON "public"."tf_catalogos" USING "btree" ("cambio_listas_peps") WHERE ("cambio_listas_peps" IS NOT NULL);



CREATE INDEX "idx_tfc_catalogo_id" ON "public"."tf_catalogos" USING "btree" ("catalogo_id") WHERE ("catalogo_id" IS NOT NULL);



CREATE INDEX "idx_tfc_edad" ON "public"."tf_catalogos" USING "btree" ("edad") WHERE ("edad" IS NOT NULL);



CREATE INDEX "idx_tfc_frecuencia" ON "public"."tf_catalogos" USING "btree" ("id_opcion") WHERE ("frecuencia" IS NOT NULL);



CREATE INDEX "idx_tfc_incremento_vs_monto" ON "public"."tf_catalogos" USING "btree" ("incremento_vs_monto_anterior") WHERE ("incremento_vs_monto_anterior" IS NOT NULL);



CREATE INDEX "idx_tfc_liquidacion_anticipada" ON "public"."tf_catalogos" USING "btree" ("liquidacion_anticipada") WHERE ("liquidacion_anticipada" IS NOT NULL);



CREATE INDEX "idx_tfc_pago_excedido" ON "public"."tf_catalogos" USING "btree" ("pago_excedido") WHERE ("pago_excedido" IS NOT NULL);



CREATE INDEX "idx_tfc_senial_alerta_historica" ON "public"."tf_catalogos" USING "btree" ("senial_alerta_historica") WHERE ("senial_alerta_historica" IS NOT NULL);



CREATE INDEX "idx_tfc_tipo_peps" ON "public"."tf_catalogos" USING "btree" ("tipo_peps") WHERE ("tipo_peps" IS NOT NULL);



CREATE OR REPLACE TRIGGER "trg_alerta_roi24_peps" AFTER INSERT ON "public"."operaciones" FOR EACH ROW EXECUTE FUNCTION "public"."fn_alerta_roi24_peps"();



CREATE OR REPLACE TRIGGER "trg_alerta_roi_inconsistente" AFTER INSERT ON "public"."operaciones" FOR EACH ROW EXECUTE FUNCTION "public"."fn_alerta_roi_perfil_inconsistente"();



CREATE OR REPLACE TRIGGER "trg_alerta_roip" AFTER INSERT ON "public"."reportes" FOR EACH ROW EXECUTE FUNCTION "public"."fn_alerta_roip"();



CREATE OR REPLACE TRIGGER "trg_alerta_ror" AFTER INSERT ON "public"."operaciones" FOR EACH ROW EXECUTE FUNCTION "public"."fn_alerta_ror_moneda_extranjera"();



CREATE OR REPLACE TRIGGER "trg_reporte_roi24" AFTER INSERT ON "public"."alertas" FOR EACH ROW EXECUTE FUNCTION "public"."fn_reporte_roi24"();



CREATE OR REPLACE TRIGGER "trg_reporte_roi_aprobado" AFTER UPDATE OF "esta_aprobado" ON "public"."alertas" FOR EACH ROW EXECUTE FUNCTION "public"."fn_reporte_roi_aprobado"();



CREATE OR REPLACE TRIGGER "trg_reporte_ror" AFTER INSERT ON "public"."alertas" FOR EACH ROW EXECUTE FUNCTION "public"."fn_reporte_ror"();



CREATE OR REPLACE TRIGGER "trg_set_campos_cliente" BEFORE INSERT ON "public"."clientes" FOR EACH ROW EXECUTE FUNCTION "public"."fn_set_campos_cliente"();



CREATE OR REPLACE TRIGGER "trg_set_campos_contrato" BEFORE INSERT ON "public"."contratos" FOR EACH ROW EXECUTE FUNCTION "public"."fn_set_campos_contrato"();



CREATE OR REPLACE TRIGGER "trg_set_campos_operacion" BEFORE INSERT ON "public"."operaciones" FOR EACH ROW EXECUTE FUNCTION "public"."fn_set_campos_operacion"();



CREATE OR REPLACE TRIGGER "trg_set_plazo_dictamen" BEFORE INSERT ON "public"."reportes" FOR EACH ROW EXECUTE FUNCTION "public"."fn_set_plazo_dictamen"();



ALTER TABLE ONLY "public"."alertas"
    ADD CONSTRAINT "alertas_reporte_id_fkey" FOREIGN KEY ("reporte_id") REFERENCES "public"."reportes"("reporte_id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."clientes"
    ADD CONSTRAINT "clientes_id_lista_hallado_fkey" FOREIGN KEY ("id_lista_hallado") REFERENCES "public"."listas_riesgo"("lista_id");



ALTER TABLE ONLY "public"."criterios"
    ADD CONSTRAINT "criterios_id_catalogo_fkey" FOREIGN KEY ("id_catalogo") REFERENCES "public"."tf_tipos"("tipo_id");



ALTER TABLE ONLY "public"."criterios"
    ADD CONSTRAINT "criterios_id_operador_fkey" FOREIGN KEY ("id_operador") REFERENCES "public"."tf_operadores"("id_operador");



ALTER TABLE ONLY "public"."logs_auditoria"
    ADD CONSTRAINT "fk_acciones_logs" FOREIGN KEY ("id_tipo_accion") REFERENCES "public"."tf_tipos_acciones"("id_tipo_accion");



ALTER TABLE ONLY "public"."alertas"
    ADD CONSTRAINT "fk_alertas_operacion" FOREIGN KEY ("operacion_id") REFERENCES "public"."operaciones"("operacion_id");



ALTER TABLE ONLY "public"."alertas"
    ADD CONSTRAINT "fk_alertas_regla" FOREIGN KEY ("regla_id") REFERENCES "public"."reglas"("regla_id");



ALTER TABLE ONLY "public"."alertas"
    ADD CONSTRAINT "fk_alertas_sofom" FOREIGN KEY ("sofom_id") REFERENCES "public"."sofom"("sofom_id");



ALTER TABLE ONLY "public"."alertas"
    ADD CONSTRAINT "fk_alertas_tipo_alerta" FOREIGN KEY ("tipo_alerta_id") REFERENCES "public"."tf_tipos_alerta"("tipo_alerta_id");



ALTER TABLE ONLY "public"."alertas"
    ADD CONSTRAINT "fk_alertas_tipo_reporte" FOREIGN KEY ("tipo_reporte_id") REFERENCES "public"."tf_tipos_reporte"("tipo_reporte_id");



ALTER TABLE ONLY "public"."clientes"
    ADD CONSTRAINT "fk_clientes_sofom" FOREIGN KEY ("sofom_id") REFERENCES "public"."sofom"("sofom_id");



ALTER TABLE ONLY "public"."clientes"
    ADD CONSTRAINT "fk_clientes_tipo_persona" FOREIGN KEY ("id_tipo_persona") REFERENCES "public"."tf_tipos_persona"("tipo_persona_id");



ALTER TABLE ONLY "public"."contratos"
    ADD CONSTRAINT "fk_contratos_id_ultima_operacion" FOREIGN KEY ("id_ultima_operacion") REFERENCES "public"."operaciones"("operacion_id");



ALTER TABLE ONLY "public"."contratos"
    ADD CONSTRAINT "fk_contratos_perfiles_cliente" FOREIGN KEY ("perfiles_cliente_id") REFERENCES "public"."perfiles_cliente"("perfiles_cliente_id");



ALTER TABLE ONLY "public"."contratos"
    ADD CONSTRAINT "fk_contratos_sofom" FOREIGN KEY ("sofom_id") REFERENCES "public"."sofom"("sofom_id");



ALTER TABLE ONLY "public"."documentos"
    ADD CONSTRAINT "fk_documentos_perfiles_cliente" FOREIGN KEY ("perfiles_cliente_id") REFERENCES "public"."perfiles_cliente"("perfiles_cliente_id");



ALTER TABLE ONLY "public"."documentos"
    ADD CONSTRAINT "fk_documentos_tipo" FOREIGN KEY ("tipo_documento_id") REFERENCES "public"."tf_tipos_documento"("tipo_documento_id");



ALTER TABLE ONLY "public"."listas_riesgo"
    ADD CONSTRAINT "fk_listas_sofom" FOREIGN KEY ("sofom_id") REFERENCES "public"."sofom"("sofom_id");



ALTER TABLE ONLY "public"."operaciones"
    ADD CONSTRAINT "fk_operaciones_contrato" FOREIGN KEY ("contrato_id") REFERENCES "public"."contratos"("contrato_id");



ALTER TABLE ONLY "public"."perfiles_cliente"
    ADD CONSTRAINT "fk_perfiles_cliente_cliente" FOREIGN KEY ("cliente_id") REFERENCES "public"."clientes"("cliente_id");



ALTER TABLE ONLY "public"."perfiles_cliente"
    ADD CONSTRAINT "fk_perfiles_cliente_sofom" FOREIGN KEY ("sofom_id") REFERENCES "public"."sofom"("sofom_id");



ALTER TABLE ONLY "public"."reglas"
    ADD CONSTRAINT "fk_reglas_sofom" FOREIGN KEY ("sofom_id") REFERENCES "public"."sofom"("sofom_id");



ALTER TABLE ONLY "public"."reglas"
    ADD CONSTRAINT "fk_reglas_tipo_entidad" FOREIGN KEY ("tipo_entidad_id") REFERENCES "public"."tf_tipos_entidad"("tipo_entidad_id");



ALTER TABLE ONLY "public"."reglas"
    ADD CONSTRAINT "fk_reglas_tipo_regla" FOREIGN KEY ("tipo_regla_id") REFERENCES "public"."tf_tipos_regla"("tipo_regla_id");



ALTER TABLE ONLY "public"."reglas"
    ADD CONSTRAINT "fk_reglas_tipo_reporte" FOREIGN KEY ("tipo_reporte_id") REFERENCES "public"."tf_tipos_reporte"("tipo_reporte_id");



ALTER TABLE ONLY "public"."reportes"
    ADD CONSTRAINT "fk_reportes_operacion" FOREIGN KEY ("operacion_id") REFERENCES "public"."operaciones"("operacion_id");



ALTER TABLE ONLY "public"."reportes"
    ADD CONSTRAINT "fk_reportes_sofom" FOREIGN KEY ("sofom_id") REFERENCES "public"."sofom"("sofom_id");



ALTER TABLE ONLY "public"."reportes"
    ADD CONSTRAINT "fk_reportes_tipo_entidad" FOREIGN KEY ("tipo_entidad_id") REFERENCES "public"."tf_tipos_entidad"("tipo_entidad_id");



ALTER TABLE ONLY "public"."reportes"
    ADD CONSTRAINT "fk_reportes_tipo_reporte" FOREIGN KEY ("tipo_reporte_id") REFERENCES "public"."tf_tipos_reporte"("tipo_reporte_id");



ALTER TABLE ONLY "public"."sofom"
    ADD CONSTRAINT "fk_sofom_tipo_entidad" FOREIGN KEY ("tipo_entidad_id") REFERENCES "public"."tf_tipos_entidad"("tipo_entidad_id");



ALTER TABLE ONLY "public"."tf_catalogos"
    ADD CONSTRAINT "fk_tf_catalogos_clasificacion" FOREIGN KEY ("clasificacion_id") REFERENCES "public"."tf_clasificaciones"("clasificacion_id");



ALTER TABLE ONLY "public"."tf_catalogos"
    ADD CONSTRAINT "fk_tf_catalogos_criterio" FOREIGN KEY ("catalogo_id") REFERENCES "public"."tf_criterios_ebr"("id");



ALTER TABLE ONLY "public"."tf_catalogos"
    ADD CONSTRAINT "fk_tf_catalogos_tipo" FOREIGN KEY ("tipo_id") REFERENCES "public"."tf_tipos"("tipo_id");



ALTER TABLE ONLY "public"."tf_tipos_documento"
    ADD CONSTRAINT "fk_tiposdocumento_tipopersona" FOREIGN KEY ("tipo_persona_id") REFERENCES "public"."tf_tipos_persona"("tipo_persona_id");



ALTER TABLE ONLY "public"."usuarios"
    ADD CONSTRAINT "fk_usuarios_roles" FOREIGN KEY ("rol_id") REFERENCES "public"."roles"("rol_id");



ALTER TABLE ONLY "public"."usuarios"
    ADD CONSTRAINT "fk_usuarios_sofom" FOREIGN KEY ("sofom_id") REFERENCES "public"."sofom"("sofom_id");



ALTER TABLE ONLY "public"."listas_riesgo"
    ADD CONSTRAINT "listas_riesgo_tipo_fkey" FOREIGN KEY ("tipo") REFERENCES "public"."tf_tipos_origen"("id");



ALTER TABLE ONLY "public"."regla_criterios"
    ADD CONSTRAINT "regla_criterios_criterio_id_fkey" FOREIGN KEY ("criterio_id") REFERENCES "public"."criterios"("criterio_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."regla_criterios"
    ADD CONSTRAINT "regla_criterios_regla_id_fkey" FOREIGN KEY ("regla_id") REFERENCES "public"."reglas"("regla_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."tf_catalogos"
    ADD CONSTRAINT "tf_catalogos_tipo_peps_fkey" FOREIGN KEY ("tipo_peps") REFERENCES "public"."tf_tipos_origen"("id");



GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



GRANT ALL ON FUNCTION "public"."calcular_puntaje_perfil"("p_perfil_id" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."calcular_puntaje_perfil"("p_perfil_id" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."calcular_puntaje_perfil"("p_perfil_id" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_alerta_roi24_peps"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_alerta_roi24_peps"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_alerta_roi24_peps"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_alerta_roi_perfil_inconsistente"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_alerta_roi_perfil_inconsistente"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_alerta_roi_perfil_inconsistente"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_alerta_roip"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_alerta_roip"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_alerta_roip"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_alerta_ror_moneda_extranjera"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_alerta_ror_moneda_extranjera"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_alerta_ror_moneda_extranjera"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_job_alerta_dictamen_roi"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_job_alerta_dictamen_roi"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_job_alerta_dictamen_roi"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_job_alerta_dictamen_roip"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_job_alerta_dictamen_roip"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_job_alerta_dictamen_roip"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_job_alerta_entrega_roi"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_job_alerta_entrega_roi"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_job_alerta_entrega_roi"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_job_alerta_entrega_roi24"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_job_alerta_entrega_roi24"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_job_alerta_entrega_roi24"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_job_alerta_entrega_roip"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_job_alerta_entrega_roip"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_job_alerta_entrega_roip"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_job_alerta_entrega_ror"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_job_alerta_entrega_ror"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_job_alerta_entrega_ror"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_job_alerta_perfil_mensual"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_job_alerta_perfil_mensual"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_job_alerta_perfil_mensual"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_job_busqueda_listas_riesgo"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_job_busqueda_listas_riesgo"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_job_busqueda_listas_riesgo"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_job_calcular_riesgo_perfiles"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_job_calcular_riesgo_perfiles"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_job_calcular_riesgo_perfiles"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_reporte_roi24"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_reporte_roi24"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_reporte_roi24"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_reporte_roi_aprobado"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_reporte_roi_aprobado"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_reporte_roi_aprobado"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_reporte_ror"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_reporte_ror"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_reporte_ror"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_set_campos_cliente"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_set_campos_cliente"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_set_campos_cliente"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_set_campos_contrato"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_set_campos_contrato"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_set_campos_contrato"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_set_campos_operacion"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_set_campos_operacion"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_set_campos_operacion"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_set_plazo_dictamen"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_set_plazo_dictamen"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_set_plazo_dictamen"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_tipo_entidad_de_sofom"("p_sofom_id" smallint) TO "anon";
GRANT ALL ON FUNCTION "public"."fn_tipo_entidad_de_sofom"("p_sofom_id" smallint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_tipo_entidad_de_sofom"("p_sofom_id" smallint) TO "service_role";



GRANT ALL ON FUNCTION "public"."normalizar_texto"("p_texto" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."normalizar_texto"("p_texto" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."normalizar_texto"("p_texto" "text") TO "service_role";



GRANT ALL ON TABLE "public"."alertas" TO "anon";
GRANT ALL ON TABLE "public"."alertas" TO "authenticated";
GRANT ALL ON TABLE "public"."alertas" TO "service_role";



GRANT ALL ON SEQUENCE "public"."alertas_alerta_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."alertas_alerta_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."alertas_alerta_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."clientes" TO "anon";
GRANT ALL ON TABLE "public"."clientes" TO "authenticated";
GRANT ALL ON TABLE "public"."clientes" TO "service_role";



GRANT ALL ON SEQUENCE "public"."clientes_cliente_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."clientes_cliente_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."clientes_cliente_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."contratos" TO "anon";
GRANT ALL ON TABLE "public"."contratos" TO "authenticated";
GRANT ALL ON TABLE "public"."contratos" TO "service_role";



GRANT ALL ON SEQUENCE "public"."contratos_contrato_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."contratos_contrato_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."contratos_contrato_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."criterios" TO "anon";
GRANT ALL ON TABLE "public"."criterios" TO "authenticated";
GRANT ALL ON TABLE "public"."criterios" TO "service_role";



GRANT ALL ON SEQUENCE "public"."criterios_criterio_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."criterios_criterio_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."criterios_criterio_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."documentos" TO "anon";
GRANT ALL ON TABLE "public"."documentos" TO "authenticated";
GRANT ALL ON TABLE "public"."documentos" TO "service_role";



GRANT ALL ON SEQUENCE "public"."documentos_documento_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."documentos_documento_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."documentos_documento_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."listas_riesgo" TO "anon";
GRANT ALL ON TABLE "public"."listas_riesgo" TO "authenticated";
GRANT ALL ON TABLE "public"."listas_riesgo" TO "service_role";



GRANT ALL ON SEQUENCE "public"."listas_riesgo_lista_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."listas_riesgo_lista_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."listas_riesgo_lista_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."logs_auditoria" TO "anon";
GRANT ALL ON TABLE "public"."logs_auditoria" TO "authenticated";
GRANT ALL ON TABLE "public"."logs_auditoria" TO "service_role";



GRANT ALL ON SEQUENCE "public"."logs_auditoria_id_accion_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."logs_auditoria_id_accion_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."logs_auditoria_id_accion_seq" TO "service_role";



GRANT ALL ON TABLE "public"."operaciones" TO "anon";
GRANT ALL ON TABLE "public"."operaciones" TO "authenticated";
GRANT ALL ON TABLE "public"."operaciones" TO "service_role";



GRANT ALL ON SEQUENCE "public"."operaciones_operacion_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."operaciones_operacion_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."operaciones_operacion_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."perfiles_cliente" TO "anon";
GRANT ALL ON TABLE "public"."perfiles_cliente" TO "authenticated";
GRANT ALL ON TABLE "public"."perfiles_cliente" TO "service_role";



GRANT ALL ON SEQUENCE "public"."perfiles_cliente_perfiles_cliente_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."perfiles_cliente_perfiles_cliente_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."perfiles_cliente_perfiles_cliente_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."regla_criterios" TO "anon";
GRANT ALL ON TABLE "public"."regla_criterios" TO "authenticated";
GRANT ALL ON TABLE "public"."regla_criterios" TO "service_role";



GRANT ALL ON TABLE "public"."reglas" TO "anon";
GRANT ALL ON TABLE "public"."reglas" TO "authenticated";
GRANT ALL ON TABLE "public"."reglas" TO "service_role";



GRANT ALL ON SEQUENCE "public"."reglas_regla_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."reglas_regla_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."reglas_regla_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."reportes" TO "anon";
GRANT ALL ON TABLE "public"."reportes" TO "authenticated";
GRANT ALL ON TABLE "public"."reportes" TO "service_role";



GRANT ALL ON SEQUENCE "public"."reportes_reporte_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."reportes_reporte_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."reportes_reporte_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."roles" TO "anon";
GRANT ALL ON TABLE "public"."roles" TO "authenticated";
GRANT ALL ON TABLE "public"."roles" TO "service_role";



GRANT ALL ON SEQUENCE "public"."roles_rol_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."roles_rol_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."roles_rol_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."session" TO "anon";
GRANT ALL ON TABLE "public"."session" TO "authenticated";
GRANT ALL ON TABLE "public"."session" TO "service_role";



GRANT ALL ON TABLE "public"."sofom" TO "anon";
GRANT ALL ON TABLE "public"."sofom" TO "authenticated";
GRANT ALL ON TABLE "public"."sofom" TO "service_role";



GRANT ALL ON SEQUENCE "public"."sofom_sofom_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."sofom_sofom_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."sofom_sofom_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."tf_catalogos" TO "anon";
GRANT ALL ON TABLE "public"."tf_catalogos" TO "authenticated";
GRANT ALL ON TABLE "public"."tf_catalogos" TO "service_role";



GRANT ALL ON SEQUENCE "public"."tf_catalogos_id_opcion_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."tf_catalogos_id_opcion_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."tf_catalogos_id_opcion_seq" TO "service_role";



GRANT ALL ON TABLE "public"."tf_clasificaciones" TO "anon";
GRANT ALL ON TABLE "public"."tf_clasificaciones" TO "authenticated";
GRANT ALL ON TABLE "public"."tf_clasificaciones" TO "service_role";



GRANT ALL ON TABLE "public"."tf_criterios_ebr" TO "anon";
GRANT ALL ON TABLE "public"."tf_criterios_ebr" TO "authenticated";
GRANT ALL ON TABLE "public"."tf_criterios_ebr" TO "service_role";



GRANT ALL ON TABLE "public"."tf_operadores" TO "anon";
GRANT ALL ON TABLE "public"."tf_operadores" TO "authenticated";
GRANT ALL ON TABLE "public"."tf_operadores" TO "service_role";



GRANT ALL ON SEQUENCE "public"."tf_operadores_id_operador_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."tf_operadores_id_operador_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."tf_operadores_id_operador_seq" TO "service_role";



GRANT ALL ON TABLE "public"."tf_tipos" TO "anon";
GRANT ALL ON TABLE "public"."tf_tipos" TO "authenticated";
GRANT ALL ON TABLE "public"."tf_tipos" TO "service_role";



GRANT ALL ON TABLE "public"."tf_tipos_acciones" TO "anon";
GRANT ALL ON TABLE "public"."tf_tipos_acciones" TO "authenticated";
GRANT ALL ON TABLE "public"."tf_tipos_acciones" TO "service_role";



GRANT ALL ON SEQUENCE "public"."tf_tipos_acciones_id_tipo_accion_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."tf_tipos_acciones_id_tipo_accion_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."tf_tipos_acciones_id_tipo_accion_seq" TO "service_role";



GRANT ALL ON TABLE "public"."tf_tipos_alerta" TO "anon";
GRANT ALL ON TABLE "public"."tf_tipos_alerta" TO "authenticated";
GRANT ALL ON TABLE "public"."tf_tipos_alerta" TO "service_role";



GRANT ALL ON SEQUENCE "public"."tf_tipos_alerta_tipo_alerta_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."tf_tipos_alerta_tipo_alerta_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."tf_tipos_alerta_tipo_alerta_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."tf_tipos_documento" TO "anon";
GRANT ALL ON TABLE "public"."tf_tipos_documento" TO "authenticated";
GRANT ALL ON TABLE "public"."tf_tipos_documento" TO "service_role";



GRANT ALL ON SEQUENCE "public"."tf_tipos_documento_tipo_documento_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."tf_tipos_documento_tipo_documento_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."tf_tipos_documento_tipo_documento_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."tf_tipos_entidad" TO "anon";
GRANT ALL ON TABLE "public"."tf_tipos_entidad" TO "authenticated";
GRANT ALL ON TABLE "public"."tf_tipos_entidad" TO "service_role";



GRANT ALL ON SEQUENCE "public"."tf_tipos_entidad_tipo_entidad_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."tf_tipos_entidad_tipo_entidad_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."tf_tipos_entidad_tipo_entidad_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."tf_tipos_origen" TO "anon";
GRANT ALL ON TABLE "public"."tf_tipos_origen" TO "authenticated";
GRANT ALL ON TABLE "public"."tf_tipos_origen" TO "service_role";



GRANT ALL ON SEQUENCE "public"."tf_tipos_origen_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."tf_tipos_origen_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."tf_tipos_origen_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."tf_tipos_persona" TO "anon";
GRANT ALL ON TABLE "public"."tf_tipos_persona" TO "authenticated";
GRANT ALL ON TABLE "public"."tf_tipos_persona" TO "service_role";



GRANT ALL ON SEQUENCE "public"."tf_tipos_persona_tipo_persona_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."tf_tipos_persona_tipo_persona_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."tf_tipos_persona_tipo_persona_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."tf_tipos_regla" TO "anon";
GRANT ALL ON TABLE "public"."tf_tipos_regla" TO "authenticated";
GRANT ALL ON TABLE "public"."tf_tipos_regla" TO "service_role";



GRANT ALL ON SEQUENCE "public"."tf_tipos_regla_tipo_regla_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."tf_tipos_regla_tipo_regla_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."tf_tipos_regla_tipo_regla_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."tf_tipos_reporte" TO "anon";
GRANT ALL ON TABLE "public"."tf_tipos_reporte" TO "authenticated";
GRANT ALL ON TABLE "public"."tf_tipos_reporte" TO "service_role";



GRANT ALL ON SEQUENCE "public"."tf_tipos_reporte_tipo_reporte_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."tf_tipos_reporte_tipo_reporte_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."tf_tipos_reporte_tipo_reporte_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."usuarios" TO "anon";
GRANT ALL ON TABLE "public"."usuarios" TO "authenticated";
GRANT ALL ON TABLE "public"."usuarios" TO "service_role";



GRANT ALL ON SEQUENCE "public"."usuarios_usuario_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."usuarios_usuario_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."usuarios_usuario_id_seq" TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";







