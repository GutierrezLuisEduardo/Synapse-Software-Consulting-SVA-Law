const db = require('../util/database');

module.exports = class Operacion {

    static async fetchPaginated(limit, offset, sofomId) {
        const query = `
            WITH ops AS (
                SELECT
                    o.operacion_id,
                    o.contrato_id,
                    o.monto,
                    o.emision_operacion,
                    c.cliente_id,
                    c.razon_social                   AS nombre_cliente,
                    o.origen_recursos,
                    o.origen_operacion,
                    o.destino_operacion,
                    o.instrumento_monetario,
                    o.incremento_monto_vs_anterior,
                    o.pago_excedido
                FROM operaciones o
                INNER JOIN contratos ct        ON o.contrato_id          = ct.contrato_id
                INNER JOIN perfiles_cliente pc ON ct.perfiles_cliente_id = pc.perfiles_cliente_id
                INNER JOIN clientes c          ON pc.cliente_id          = c.cliente_id
                WHERE c.sofom_id = $3
                ORDER BY o.operacion_id ASC
                LIMIT $1 OFFSET $2
            ),
            ids AS (
                SELECT DISTINCT unnest(ARRAY[
                    origen_recursos, origen_operacion, destino_operacion,
                    instrumento_monetario, incremento_monto_vs_anterior, pago_excedido
                ]) AS id_opcion
                FROM ops
            ),
            cat AS (
                SELECT tc.id_opcion, tc.opciones
                FROM tf_catalogos tc
                INNER JOIN ids ON tc.id_opcion = ids.id_opcion
            )
            SELECT
                ops.operacion_id,
                ops.contrato_id,
                ops.monto,
                ops.emision_operacion,
                ops.cliente_id,
                ops.nombre_cliente,
                or_cat.opciones   AS origen_recursos,
                ori_cat.opciones  AS origen_operacion,
                dst_cat.opciones  AS destino_operacion,
                ins_cat.opciones  AS instrumento_monetario,
                inc_cat.opciones  AS incremento_monto_vs_anterior,
                pag_cat.opciones  AS pago_excedido
            FROM ops
            LEFT JOIN cat or_cat  ON or_cat.id_opcion  = ops.origen_recursos
            LEFT JOIN cat ori_cat ON ori_cat.id_opcion = ops.origen_operacion
            LEFT JOIN cat dst_cat ON dst_cat.id_opcion = ops.destino_operacion
            LEFT JOIN cat ins_cat ON ins_cat.id_opcion = ops.instrumento_monetario
            LEFT JOIN cat inc_cat ON inc_cat.id_opcion = ops.incremento_monto_vs_anterior
            LEFT JOIN cat pag_cat ON pag_cat.id_opcion = ops.pago_excedido
        `;
        return db.query(query, [limit, offset, sofomId]);
    }

    static async count(sofomId) {
        const query = `
            SELECT COUNT(*) AS total
            FROM operaciones o
            INNER JOIN contratos ct        ON o.contrato_id           = ct.contrato_id
            INNER JOIN perfiles_cliente pc ON ct.perfiles_cliente_id  = pc.perfiles_cliente_id
            INNER JOIN clientes c          ON pc.cliente_id           = c.cliente_id
            WHERE c.sofom_id = $1
        `;
        return db.query(query, [sofomId]);
    }

    static async fetchById(operacionId, sofomId) {
        const query = `
            SELECT
                o.operacion_id,
                o.contrato_id,
                o.monto,
                o.emision_operacion,
                c.cliente_id,
                c.razon_social              AS nombre_cliente,
                c.correo_electronico,
                c.telefono,
                (SELECT tc.opciones FROM tf_catalogos tc WHERE tc.id_opcion = o.origen_recursos)              AS origen_recursos,
                (SELECT tc.opciones FROM tf_catalogos tc WHERE tc.id_opcion = o.origen_operacion)             AS origen_operacion,
                (SELECT tc.opciones FROM tf_catalogos tc WHERE tc.id_opcion = o.destino_operacion)            AS destino_operacion,
                (SELECT tc.opciones FROM tf_catalogos tc WHERE tc.id_opcion = o.instrumento_monetario)        AS instrumento_monetario,
                (SELECT tc.opciones FROM tf_catalogos tc WHERE tc.id_opcion = o.incremento_monto_vs_anterior) AS incremento_monto_vs_anterior,
                (SELECT tc.opciones FROM tf_catalogos tc WHERE tc.id_opcion = o.pago_excedido)                AS pago_excedido,
                ct.descripcion              AS contrato_descripcion,
                ct.monto_total_pago,
                ct.monto_pagado,
                ct.numero_pagos_hechos,
                ct.numero_pagos_acordados,
                ct.fecha_inicio             AS contrato_inicio,
                ct.fecha_finalizacion       AS contrato_fin,
                s.razon_social              AS sofom_nombre
            FROM operaciones o
            INNER JOIN contratos ct        ON o.contrato_id          = ct.contrato_id
            INNER JOIN perfiles_cliente pc ON ct.perfiles_cliente_id = pc.perfiles_cliente_id
            INNER JOIN clientes c          ON pc.cliente_id          = c.cliente_id
            INNER JOIN sofom s             ON c.sofom_id             = s.sofom_id
            WHERE o.operacion_id = $1 AND c.sofom_id = $2
        `;
        return db.query(query, [operacionId, sofomId]);
    }

    static async fetchByClienteId(clienteId, sofomId) {
        const query = `
            WITH ops AS (
                SELECT
                    o.operacion_id,
                    o.contrato_id,
                    o.monto,
                    o.emision_operacion,
                    c.razon_social                   AS nombre_cliente,
                    o.origen_recursos,
                    o.origen_operacion,
                    o.destino_operacion,
                    o.instrumento_monetario,
                    o.incremento_monto_vs_anterior,
                    o.pago_excedido
                FROM operaciones o
                INNER JOIN contratos ct        ON o.contrato_id          = ct.contrato_id
                INNER JOIN perfiles_cliente pc ON ct.perfiles_cliente_id = pc.perfiles_cliente_id
                INNER JOIN clientes c          ON pc.cliente_id          = c.cliente_id
                WHERE pc.cliente_id = $1
                AND c.sofom_id    = $2
            ),
            ids AS (
                SELECT DISTINCT unnest(ARRAY[
                    origen_recursos, origen_operacion, destino_operacion,
                    instrumento_monetario, incremento_monto_vs_anterior, pago_excedido
                ]) AS id_opcion
                FROM ops
            ),
            cat AS (
                SELECT tc.id_opcion, tc.opciones
                FROM tf_catalogos tc
                INNER JOIN ids ON tc.id_opcion = ids.id_opcion
            )
            SELECT
                ops.operacion_id,
                ops.contrato_id,
                ops.monto,
                ops.emision_operacion,
                ops.nombre_cliente,
                or_cat.opciones   AS origen_recursos,
                ori_cat.opciones  AS origen_operacion,
                dst_cat.opciones  AS destino_operacion,
                ins_cat.opciones  AS instrumento_monetario,
                inc_cat.opciones  AS incremento_monto_vs_anterior,
                pag_cat.opciones  AS pago_excedido
            FROM ops
            LEFT JOIN cat or_cat  ON or_cat.id_opcion  = ops.origen_recursos
            LEFT JOIN cat ori_cat ON ori_cat.id_opcion = ops.origen_operacion
            LEFT JOIN cat dst_cat ON dst_cat.id_opcion = ops.destino_operacion
            LEFT JOIN cat ins_cat ON ins_cat.id_opcion = ops.instrumento_monetario
            LEFT JOIN cat inc_cat ON inc_cat.id_opcion = ops.incremento_monto_vs_anterior
            LEFT JOIN cat pag_cat ON pag_cat.id_opcion = ops.pago_excedido
            ORDER BY ops.emision_operacion DESC
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

    static async fetchContratosDeCliente(clienteId, sofomId) {
        const query = `
            SELECT
                ct.contrato_id,
                ct.descripcion,
                ct.monto_total_pago,
                ct.monto_pagado,
                ct.fecha_inicio,
                ct.fecha_finalizacion
            FROM contratos ct
            INNER JOIN perfiles_cliente pc ON ct.perfiles_cliente_id = pc.perfiles_cliente_id
            INNER JOIN clientes c          ON pc.cliente_id           = c.cliente_id
            WHERE pc.cliente_id = $1
              AND c.sofom_id    = $2
            ORDER BY ct.contrato_id ASC
        `;
        return db.query(query, [clienteId, sofomId]);
    }

    static async create({
        contrato_id,
        monto,
        emision_operacion,
        origen_recursos,
        origen_operacion,
        destino_operacion,
        instrumento_monetario,
    }) {
        const query = `
            INSERT INTO operaciones (
                contrato_id,
                monto,
                emision_operacion,
                origen_recursos,
                origen_operacion,
                destino_operacion,
                instrumento_monetario
            ) VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING operacion_id
        `;
        return db.query(query, [
            contrato_id,
            monto,
            emision_operacion,
            origen_recursos,
            origen_operacion,
            destino_operacion,
            instrumento_monetario,
        ]);
    }

    static async updateUltimaOperacion(contratoId, operacionId) {
        const query = `
            UPDATE contratos
            SET id_ultima_operacion = $1
            WHERE contrato_id = $2
        `;
        return db.query(query, [operacionId, contratoId]);
    }
    
};