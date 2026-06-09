const db = require('../util/database');

module.exports = class Reporte {
    static async createROIP({ sofomId, asunto, descripcion, evidencia = null }) {
        const query = `
            INSERT INTO reportes (
                sofom_id,
                tipo_reporte_id,
                tipo_entidad_id,
                asunto,
                descripcion,
                evidencia,
                fecha_generacion,
                plazo_dictamen,
                ha_sido_descargado,
                dictamen_emitido
            )
            SELECT
                $1,
                3,
                s.tipo_entidad_id,
                $2,
                $3,
                $4,
                NOW(),
                (NOW() + (tr.dias_hasta_dictamen || ' days')::INTERVAL)::DATE,
                FALSE,
                FALSE
            FROM tf_tipos_reporte tr
            CROSS JOIN sofom s
            WHERE tr.tipo_reporte_id = 3
              AND s.sofom_id = $1
            RETURNING reporte_id
        `;
        return db.query(query, [sofomId, asunto, descripcion, evidencia]);
    }

    // Obtiene la configuración del tipo de reporte ROIP (tipo_reporte_id = 3).
    static async fetchTipoROIP() {
        const query = `
            SELECT
                tipo_reporte_id,
                descripcion,
                requiere_dictamen,
                dias_hasta_dictamen
            FROM tf_tipos_reporte
            WHERE tipo_reporte_id = 3
        `;
        return db.query(query);
    }

    /**
     * Obtiene un reporte por su reporte_id y sofom_id.
     *
     * Método agregado para uso en el detalle de alerta:
     * el campo 'alertas.reporte_id' apunta directamente al reporte generado.
     * Esto cubre casos como ROIP donde operacion_id es NULL en ambas tablas.
     */
    static async fetchById(reporteId, sofomId) {
        const query = `
            SELECT
                r.reporte_id,
                r.asunto,
                r.descripcion,
                r.evidencia,
                r.fecha_generacion,
                r.plazo_dictamen,
                r.dictamen,
                r.dictamen_emitido,
                r.ha_sido_descargado,
                tr.descripcion  AS tipo_reporte,
                tr.requiere_dictamen,
                tr.dias_hasta_dictamen
            FROM reportes r
            INNER JOIN tf_tipos_reporte tr ON r.tipo_reporte_id = tr.tipo_reporte_id
            WHERE r.reporte_id = $1
              AND r.sofom_id   = $2
        `;
        return db.query(query, [reporteId, sofomId]);
    }
};
