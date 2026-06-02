const db = require('../util/database');

module.exports = class Alerta {

    static async fetchAll(sofomId) {
        const query = `
            SELECT
                a.alerta_id,
                a.operacion_id,
                a.estado_revision,
                a.fecha_hora_alerta,
                ta.descripcion AS tipo_alerta,
                tr.descripcion AS tipo_reporte,
                tr.requiere_dictamen
            FROM alertas a
            INNER JOIN tf_tipos_alerta ta ON a.tipo_alerta_id = ta.tipo_alerta_id
            INNER JOIN tf_tipos_reporte tr ON a.tipo_reporte_id = tr.tipo_reporte_id
            WHERE a.sofom_id = $1
            ORDER BY a.fecha_hora_alerta DESC
        `;
        return db.query(query, [sofomId]);
    }

    static async fetchById(alertaId, sofomId) {
        const query = `
            SELECT
                a.alerta_id,
                a.operacion_id,
                a.estado_revision,
                a.fecha_hora_alerta,
                a.regla_id,
                ta.descripcion AS tipo_alerta,
                tr.descripcion AS tipo_reporte,
                tr.requiere_dictamen,
                tr.dias_hasta_dictamen
            FROM alertas a
            INNER JOIN tf_tipos_alerta ta ON a.tipo_alerta_id = ta.tipo_alerta_id
            INNER JOIN tf_tipos_reporte tr ON a.tipo_reporte_id = tr.tipo_reporte_id
            WHERE a.alerta_id = $1 AND a.sofom_id = $2
        `;
        return db.query(query, [alertaId, sofomId]);
    }

    static async fetchReporteByOperacion(operacionId, sofomId) {
        const query = `
            SELECT
                r.reporte_id,
                r.fecha_generacion,
                r.dictamen,
                r.plazo_dictamen,
                r.ha_sido_descargado,
                tr.descripcion AS tipo_reporte,
                tr.requiere_dictamen
            FROM reportes r
            INNER JOIN tf_tipos_reporte tr ON r.tipo_reporte_id = tr.tipo_reporte_id
            WHERE r.operacion_id = $1 AND r.sofom_id = $2
            ORDER BY r.fecha_generacion DESC
            LIMIT 1
        `;
        return db.query(query, [operacionId, sofomId]);
    }

    static async fetchByClienteId(clienteId, sofomId) {
        const query = `
            SELECT
                a.alerta_id,
                a.operacion_id,
                a.estado_revision,
                a.fecha_hora_alerta,
                ta.descripcion AS tipo_alerta,
                tr.descripcion AS tipo_reporte,
                tr.requiere_dictamen
            FROM alertas a
            INNER JOIN tf_tipos_alerta ta  ON a.tipo_alerta_id  = ta.tipo_alerta_id
            INNER JOIN tf_tipos_reporte tr ON a.tipo_reporte_id = tr.tipo_reporte_id
            -- Trazamos la cadena: alerta -> operacion -> contrato -> perfil -> cliente
            INNER JOIN operaciones o        ON a.operacion_id          = o.operacion_id
            INNER JOIN contratos ct         ON o.contrato_id           = ct.contrato_id
            INNER JOIN perfiles_cliente pc  ON ct.perfiles_cliente_id  = pc.perfiles_cliente_id
            INNER JOIN clientes c           ON pc.cliente_id           = c.cliente_id
            WHERE pc.cliente_id = $1
            AND a.sofom_id    = $2
            ORDER BY a.fecha_hora_alerta DESC
        `;
        return db.query(query, [clienteId, sofomId]);
    }
};