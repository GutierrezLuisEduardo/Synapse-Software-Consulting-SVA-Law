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

    /**
     * @param {number} sofomId 
     * @param {number} perfilClienteId
     * @param {number} tipoDocumentoId
     * @param {string} referenciaArchivo
     */
    static async create(sofomId, perfilClienteId, tipoDocumentoId, referenciaArchivo) {
        const query = `
            INSERT INTO documentos (sofom_id, perfiles_cliente_id, tipo_documento_id, referencia_archivo)
            VALUES ($1, $2, $3, $4)
            RETURNING documento_id
        `;
        return db.query(query, [sofomId, perfilClienteId, tipoDocumentoId, referenciaArchivo]);
    }

    static async fetchTiposDocumento() {
        const query = `
            SELECT tipo_documento_id, descripcion, tipo_persona_id
            FROM tf_tipos_documento
            ORDER BY tipo_persona_id ASC, descripcion ASC
        `;
        return db.query(query);
    }
};