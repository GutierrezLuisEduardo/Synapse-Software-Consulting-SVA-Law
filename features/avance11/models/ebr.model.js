const db = require('../util/database');

module.exports = class Ebr {

    // Devuelve todos los criterios EBR con su clasificación.
    static async fetchCriterios() {
        const query = `
            SELECT
                ce.id,
                ce.descripcion,
                cl.clasificacion_id,
                cl.descripcion AS clasificacion
            FROM tf_criterios_ebr ce
            INNER JOIN tf_clasificaciones cl ON ce.clasificacion_id = cl.clasificacion_id
            ORDER BY ce.clasificacion_id ASC, ce.id ASC
        `;
        return db.query(query);
    }

    // Devuelve el JSONB enfoque_riesgos de una SOFOM.
    static async fetchEnfoque(sofomId) {
        const query = `
            SELECT enfoque_riesgos, sofom_id, razon_social
            FROM sofom
            WHERE sofom_id = $1
        `;
        return db.query(query, [sofomId]);
    }

    // Actualiza el campo enfoque_riesgos de una SOFOM.
    static async updateEnfoque(sofomId, nuevoEnfoque) {
        const query = `
            UPDATE sofom
            SET enfoque_riesgos = $1::jsonb,
                ultima_revision  = NOW()
            WHERE sofom_id = $2
        `;
        return db.query(query, [JSON.stringify(nuevoEnfoque), sofomId]);
    }
};
