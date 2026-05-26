const db = require('../util/database');

module.exports = class Documento {

    static async fetchByClienteId(clienteId) {
        const query = `
            SELECT
                d.documento_id,
                d.referencia_archivo,
                d.fecha_carga,
                td.descripcion AS tipo_documento,
                td.tipo_persona_id
            FROM documentos d
            INNER JOIN tf_tipos_documento td ON d.tipo_documento_id = td.tipo_documento_id
            INNER JOIN perfiles_cliente pc ON d.perfiles_cliente_id = pc.perfiles_cliente_id
            WHERE pc.cliente_id = $1
            ORDER BY d.fecha_carga DESC
        `;
        return db.query(query, [clienteId]);
    }
};