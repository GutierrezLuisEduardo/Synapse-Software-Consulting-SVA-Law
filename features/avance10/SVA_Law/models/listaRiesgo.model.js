const db = require('../util/database');

module.exports = class ListaRiesgo {

    // Obtiene todos los tipos de origen (catálogo tf_tipos_origen).
    static async fetchTiposOrigen() {
        return db.query(`
        SELECT id, descripcion
        FROM tf_tipos_origen
        ORDER BY id ASC
        `);
    }

    // Obtiene todas las listas de riesgo de una SOFOM, con descripción del tipo.
    static async fetchBySofom(sofomId) {
        return db.query(`
        SELECT
        lr.lista_id,
        lr.tipo,
        tto.descripcion AS tipo_descripcion,
        lr.ultima_actualizacion,
        length(lr.string_lista) AS caracteres
        FROM listas_riesgo lr
        INNER JOIN tf_tipos_origen tto ON lr.tipo = tto.id
        WHERE lr.sofom_id = $1
        ORDER BY lr.lista_id DESC
        `, [sofomId]);
    }

    // Inserta una nueva lista o reemplaza la existente del mismo tipo y SOFOM.
    // Si ya existe una lista con ese tipo en esa SOFOM, se actualiza.

    static async upsert(sofomId, tipo, stringLista) {
        // Intentar actualizar primero
        const update = await db.query(`
        UPDATE listas_riesgo
        SET string_lista = $1,
        ultima_actualizacion = NOW()
        WHERE sofom_id = $2
        AND tipo = $3
        RETURNING lista_id
        `, [stringLista, sofomId, tipo]);

        if (update.rowCount > 0) {
            return { lista_id: update.rows[0].lista_id, accion: 'actualizada' };
        }

        // Si no existe, insertar
        const insert = await db.query(`
        INSERT INTO listas_riesgo (sofom_id, tipo, string_lista, ultima_actualizacion)
        VALUES ($1, $2, $3, NOW())
        RETURNING lista_id
        `, [sofomId, tipo, stringLista]);

        return { lista_id: insert.rows[0].lista_id, accion: 'creada' };
    }
};
