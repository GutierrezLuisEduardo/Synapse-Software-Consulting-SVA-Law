const db = require('../util/database');

module.exports = class Cliente {

    static async fetchPaginated(limit, offset, search = '', sofomId) {
        const query = `
            SELECT
                c.cliente_id,
                c.razon_social AS nombre_cliente,
                c.sofom_id,
                s.razon_social AS sofom_nombre,
                c.id_tipo_persona,
                tp.descripcion AS tipo_persona,
                c.fecha_creacion
            FROM clientes c
            INNER JOIN sofom s ON c.sofom_id = s.sofom_id
            LEFT JOIN tf_tipos_persona tp ON c.id_tipo_persona = tp.tipo_persona_id
            WHERE
                c.sofom_id = $4
                AND (CAST(c.cliente_id AS TEXT) ILIKE $1 OR c.razon_social ILIKE $1)
            ORDER BY c.cliente_id ASC
            LIMIT $2 OFFSET $3
        `;
        return db.query(query, [`%${search}%`, limit, offset, sofomId]);
    }

    static async count(search = '', sofomId) {
        const query = `
            SELECT COUNT(*) AS total
            FROM clientes c
            WHERE
                c.sofom_id = $2
                AND (CAST(c.cliente_id AS TEXT) ILIKE $1 OR c.razon_social ILIKE $1)
        `;
        return db.query(query, [`%${search}%`, sofomId]);
    }

static async fetchById(clienteId) {
    const query = `
        SELECT
            c.cliente_id,
            c.razon_social,
            c.telefono,
            c.correo_electronico,
            c.curp,
            c.rfc,
            c.genero,
            c.fecha_nacimiento,
            c.pais_nacimiento,
            c.fecha_creacion,
            c.id_tipo_persona,
            tp.descripcion          AS tipo_persona,
            c.sofom_id,
            s.razon_social          AS sofom_nombre,
            c.estatus_alerta_historica,
            c.ha_sido_peps,
            (SELECT tc.opciones FROM tf_catalogos tc WHERE tc.id_opcion = c.domicilio)             AS domicilio,
            (SELECT tc.opciones FROM tf_catalogos tc WHERE tc.id_opcion = c.actividad_economica)   AS actividad_economica,
            (SELECT tc.opciones FROM tf_catalogos tc WHERE tc.id_opcion = c.estado_civil)          AS estado_civil,
            (SELECT tc.opciones FROM tf_catalogos tc WHERE tc.id_opcion = c.nivel_estudios)        AS nivel_estudios,
            (SELECT tc.opciones FROM tf_catalogos tc WHERE tc.id_opcion = c.tipo_empleo)           AS tipo_empleo,
            (SELECT tc.opciones FROM tf_catalogos tc WHERE tc.id_opcion = c.ingresos_mensuales)    AS ingresos_mensuales
        FROM clientes c
        INNER JOIN sofom s          ON c.sofom_id        = s.sofom_id
        LEFT  JOIN tf_tipos_persona tp ON c.id_tipo_persona = tp.tipo_persona_id
        WHERE c.cliente_id = $1
    `;
    return db.query(query, [clienteId]);
}

    static async fetchByIdAndSofom(clienteId, sofomId) {
        const query = `
            SELECT cliente_id FROM clientes
            WHERE cliente_id = $1 AND sofom_id = $2
        `;
        return db.query(query, [clienteId, sofomId]);
    }

    static async fetchCatalogo(catalogoId) {
        const query = `
            SELECT id_opcion, opciones, valores
            FROM tf_catalogos
            WHERE catalogo_id = $1
            ORDER BY valores ASC
        `;
        return db.query(query, [catalogoId]);
    }

    static async fetchTiposPersona() {
        const query = `
            SELECT tipo_persona_id, descripcion
            FROM tf_tipos_persona
            ORDER BY tipo_persona_id ASC
        `;
        return db.query(query);
    }

    static async create({
        sofom_id,
        razon_social,
        telefono,
        correo_electronico,
        clabe,
        serie_efirma,
        geolocalizacion,
        id_tipo_persona,
        curp,
        rfc,
        genero,
        fecha_nacimiento,
        pais_nacimiento,
        entidad_federativa_nacimiento,
        nombre_apoderado_legal,
        fecha_constitucion,
        pais_origen,
        nacionalidad,
        domicilio,
        actividad_economica,
        vinculado_con_grupo,
        estado_civil,
        dependientes_economicos,
        numero_hijos,
        nivel_estudios,
        tipo_vivienda,
        tipo_empleo,
        ingresos_mensuales,
        valor_patrimonio,
        pertenece_partido_politico,
        peps,
        edad
    }) {
        const query = `
            INSERT INTO clientes (
                sofom_id, razon_social, telefono, correo_electronico,
                clabe, serie_efirma, geolocalizacion, id_tipo_persona,
                curp, rfc, genero, fecha_nacimiento, pais_nacimiento,
                entidad_federativa_nacimiento, nombre_apoderado_legal, fecha_constitucion,
                pais_origen, nacionalidad, domicilio, actividad_economica,
                vinculado_con_grupo, estado_civil, dependientes_economicos,
                numero_hijos, nivel_estudios, tipo_vivienda, tipo_empleo,
                ingresos_mensuales, valor_patrimonio, pertenece_partido_politico,
                peps, edad
            ) VALUES (
                $1, $2, $3, $4,
                $5, $6, $7, $8,
                $9, $10, $11, $12, $13,
                $14, $15, $16,
                $17, $18, $19, $20,
                $21, $22, $23,
                $24, $25, $26, $27,
                $28, $29, $30,
                $31, $32
            )
            RETURNING cliente_id
        `;
        return db.query(query, [
            sofom_id, razon_social, telefono, correo_electronico,
            clabe, serie_efirma, geolocalizacion, id_tipo_persona,
            curp || null, rfc || null, genero || null,
            fecha_nacimiento || null, pais_nacimiento || null,
            entidad_federativa_nacimiento || null, nombre_apoderado_legal || null,
            fecha_constitucion || null,
            pais_origen, nacionalidad, domicilio, actividad_economica,
            vinculado_con_grupo, estado_civil, dependientes_economicos,
            numero_hijos, nivel_estudios, tipo_vivienda, tipo_empleo,
            ingresos_mensuales, valor_patrimonio, pertenece_partido_politico,
            peps || null, edad || null
        ]);
    }

    static async fetchPerfilByClienteIdAndSofom(clienteId, sofomId) {
        const query = `
            SELECT
                pc.perfiles_cliente_id,
                c.razon_social
            FROM perfiles_cliente pc
            INNER JOIN clientes c ON pc.cliente_id = c.cliente_id
            WHERE pc.cliente_id = $1
            AND pc.sofom_id = $2
            LIMIT 1
        `;
        return db.query(query, [clienteId, sofomId]);
    }

    static async crearPerfil(clienteId, sofomId) {
        return db.query(
            `INSERT INTO perfiles_cliente (cliente_id, sofom_id) VALUES ($1, $2)`,
            [clienteId, sofomId]
        );
    }

    static async buscarPorTermino(termino, sofomId) {
        const query = `
            SELECT
                c.cliente_id,
                c.razon_social,
                c.rfc
            FROM clientes c
            WHERE
                c.sofom_id = $2
                AND (
                    CAST(c.cliente_id AS TEXT) ILIKE $1
                    OR c.razon_social ILIKE $1
                    OR c.rfc ILIKE $1
                )
            ORDER BY c.razon_social ASC
            LIMIT 10
        `;
        return db.query(query, [`%${termino}%`, sofomId]);
    }
};