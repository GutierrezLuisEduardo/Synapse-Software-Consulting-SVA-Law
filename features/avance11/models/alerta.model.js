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
                a.esta_aprobado,
                a.descripcion AS descripcion_alerta,
                a.reporte_id,
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
            LEFT JOIN operaciones o ON a.operacion_id = o.operacion_id
            LEFT JOIN contratos ct ON o.contrato_id = ct.contrato_id
            LEFT JOIN perfiles_cliente pc ON ct.perfiles_cliente_id = pc.perfiles_cliente_id
            WHERE pc.cliente_id = $1
            AND a.sofom_id = $2
            ORDER BY a.fecha_hora_alerta DESC
        `;
        return db.query(query, [clienteId, sofomId]);
    }




    // Fetch con filtros (tipo_alerta_id y tipo_reporte_id opcionales)
    static async fetchAllFiltrado(sofomId, tipoAlertaId, tipoReporteId, soloROIP) {
        const condiciones = ['a.sofom_id = $1'];
        const params = [sofomId];
        let i = 2;

        // Ocultar ROIP (tipo_reporte_id=3) a quienes no son Oficial de cumplimiento
        if (soloROIP === false) {
            condiciones.push(`a.tipo_reporte_id != 3`);
        }
        if (tipoAlertaId) {
            condiciones.push(`a.tipo_alerta_id = $${i++}`);
            params.push(tipoAlertaId);
        }
        if (tipoReporteId) {
            condiciones.push(`a.tipo_reporte_id = $${i++}`);
            params.push(tipoReporteId);
        }

        const query = `
            SELECT
                a.alerta_id, a.operacion_id, a.estado_revision,
                a.fecha_hora_alerta, a.esta_aprobado, a.descripcion,
                a.tipo_alerta_id, a.tipo_reporte_id, a.reporte_id,
                ta.descripcion AS tipo_alerta,
                tr.descripcion AS tipo_reporte,
                tr.requiere_dictamen
            FROM alertas a
            INNER JOIN tf_tipos_alerta ta  ON a.tipo_alerta_id  = ta.tipo_alerta_id
            INNER JOIN tf_tipos_reporte tr ON a.tipo_reporte_id = tr.tipo_reporte_id
            WHERE ${condiciones.join(' AND ')}
            ORDER BY a.fecha_hora_alerta DESC
        `;
        return db.query(query, params);
    }

    // Aprobar o rechazar dictamen de una alerta (esta_aprobado + descripcion)
    static async emitirDictamen(alertaId, sofomId, aprobado, descripcionDictamen) {
        const query = `
            UPDATE alertas
            SET esta_aprobado = $1,
                estado_revision = TRUE,
                descripcion = CASE WHEN $2::text IS NOT NULL THEN $2 ELSE descripcion END
            WHERE alerta_id = $3 AND sofom_id = $4
            RETURNING *
        `;
        return db.query(query, [aprobado, descripcionDictamen || null, alertaId, sofomId]);
    }

    // Fetch del reporte asociado directamente por reporte_id (para alertas que ya tienen reporte_id)
    static async fetchReporteById(reporteId, sofomId) {
        const query = `
            SELECT
                r.reporte_id, r.fecha_generacion, r.dictamen, r.plazo_dictamen,
                r.ha_sido_descargado, r.dictamen_emitido, r.asunto,
                r.descripcion, r.evidencia,
                tr.descripcion AS tipo_reporte,
                tr.requiere_dictamen,
                CASE WHEN r.plazo_dictamen IS NOT NULL
                    THEN r.plazo_dictamen - CURRENT_DATE
                    ELSE NULL
                END AS dias_restantes_dictamen
            FROM reportes r
            INNER JOIN tf_tipos_reporte tr ON r.tipo_reporte_id = tr.tipo_reporte_id
            WHERE r.reporte_id = $1 AND r.sofom_id = $2
        `;
        return db.query(query, [reporteId, sofomId]);
    }

    // Marcar reportes como descargados y retornar su contenido para exportar
    static async fetchReportesPendientesDescarga(sofomId) {
        const query = `
            SELECT r.reporte_id, r.asunto, r.descripcion, r.evidencia,
                tr.descripcion AS tipo_reporte, r.fecha_generacion
            FROM reportes r
            INNER JOIN tf_tipos_reporte tr ON r.tipo_reporte_id = tr.tipo_reporte_id
            WHERE r.sofom_id = $1 AND r.ha_sido_descargado = FALSE
            ORDER BY r.fecha_generacion DESC
        `;
        return db.query(query, [sofomId]);
    }

    static async marcarDescargados(reporteIds, sofomId) {
        const query = `
            UPDATE reportes
            SET ha_sido_descargado = TRUE
            WHERE reporte_id = ANY($1::int[]) AND sofom_id = $2
        `;
        return db.query(query, [reporteIds, sofomId]);
    }

    // Exportar historial de alertas como texto
    static async fetchHistorialCompleto(sofomId) {
        const query = `
            SELECT a.alerta_id, a.fecha_hora_alerta, a.descripcion,
                a.estado_revision, a.esta_aprobado,
                ta.descripcion AS tipo_alerta,
                tr.descripcion AS tipo_reporte
            FROM alertas a
            INNER JOIN tf_tipos_alerta ta  ON a.tipo_alerta_id  = ta.tipo_alerta_id
            INNER JOIN tf_tipos_reporte tr ON a.tipo_reporte_id = tr.tipo_reporte_id
            WHERE a.sofom_id = $1
            ORDER BY a.fecha_hora_alerta DESC
        `;
        return db.query(query, [sofomId]);
    }
};