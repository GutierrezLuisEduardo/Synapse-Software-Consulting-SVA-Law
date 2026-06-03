const db = require('../util/database');

module.exports = class Operacion {

    static async fetchPaginated(limit, offset, sofomId) {
        const query = `
            SELECT
                o.operacion_id,
                o.contrato_id,
                o.monto,
                o.emision_operacion,
                c.cliente_id,
                c.razon_social AS nombre_cliente,
                or_cat.opciones  AS origen_recursos,
                ori_cat.opciones AS origen_operacion,
                dst_cat.opciones AS destino_operacion,
                ins_cat.opciones AS instrumento_monetario,
                inc_cat.opciones AS incremento_monto_vs_anterior,
                pag_cat.opciones AS pago_excedido
            FROM operaciones o
            INNER JOIN contratos ct ON o.contrato_id = ct.contrato_id
            INNER JOIN perfiles_cliente pc ON ct.perfiles_cliente_id  = pc.perfiles_cliente_id
            INNER JOIN clientes c ON pc.cliente_id = c.cliente_id
            LEFT JOIN tf_catalogos or_cat ON or_cat.id_opcion = o.origen_recursos
            LEFT JOIN tf_catalogos ori_cat ON ori_cat.id_opcion = o.origen_operacion
            LEFT JOIN tf_catalogos dst_cat ON dst_cat.id_opcion = o.destino_operacion
            LEFT JOIN tf_catalogos ins_cat ON ins_cat.id_opcion = o.instrumento_monetario
            LEFT JOIN tf_catalogos inc_cat ON inc_cat.id_opcion = o.incremento_monto_vs_anterior
            LEFT JOIN tf_catalogos pag_cat ON pag_cat.id_opcion = o.pago_excedido
            WHERE c.sofom_id = $3
            ORDER BY o.operacion_id ASC
            LIMIT $1 OFFSET $2
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
                c.razon_social     AS nombre_cliente,
                c.correo_electronico,
                c.telefono,
                or_cat.opciones    AS origen_recursos,
                ori_cat.opciones   AS origen_operacion,
                dst_cat.opciones   AS destino_operacion,
                ins_cat.opciones   AS instrumento_monetario,
                inc_cat.opciones   AS incremento_monto_vs_anterior,
                pag_cat.opciones   AS pago_excedido,
                ct.descripcion     AS contrato_descripcion,
                ct.monto_total_pago,
                ct.monto_pagado,
                ct.numero_pagos_hechos,
                ct.numero_pagos_acordados,
                ct.fecha_inicio    AS contrato_inicio,
                ct.fecha_finalizacion AS contrato_fin,
                s.razon_social     AS sofom_nombre
            FROM operaciones o
            INNER JOIN contratos ct        ON o.contrato_id           = ct.contrato_id
            INNER JOIN perfiles_cliente pc ON ct.perfiles_cliente_id  = pc.perfiles_cliente_id
            INNER JOIN clientes c          ON pc.cliente_id           = c.cliente_id
            INNER JOIN sofom s             ON c.sofom_id              = s.sofom_id
            LEFT JOIN tf_catalogos or_cat ON or_cat.id_opcion = o.origen_recursos
            LEFT JOIN tf_catalogos ori_cat ON ori_cat.id_opcion = o.origen_operacion
            LEFT JOIN tf_catalogos dst_cat ON dst_cat.id_opcion = o.destino_operacion
            LEFT JOIN tf_catalogos ins_cat ON ins_cat.id_opcion = o.instrumento_monetario
            LEFT JOIN tf_catalogos inc_cat ON inc_cat.id_opcion = o.incremento_monto_vs_anterior
            LEFT JOIN tf_catalogos pag_cat ON pag_cat.id_opcion = o.pago_excedido
            WHERE o.operacion_id = $1 AND c.sofom_id = $2
        `;
        return db.query(query, [operacionId, sofomId]);
    }

    static async fetchByClienteId(clienteId, sofomId) {
        const query = `
            SELECT
                o.operacion_id,
                o.contrato_id,
                o.monto,
                o.emision_operacion,
                c.razon_social AS nombre_cliente,
                or_cat.opciones  AS origen_recursos,
                ori_cat.opciones AS origen_operacion,
                dst_cat.opciones AS destino_operacion,
                ins_cat.opciones AS instrumento_monetario,
                inc_cat.opciones AS incremento_monto_vs_anterior,
                pag_cat.opciones AS pago_excedido
            FROM operaciones o
            INNER JOIN contratos ct        ON o.contrato_id           = ct.contrato_id
            INNER JOIN perfiles_cliente pc ON ct.perfiles_cliente_id  = pc.perfiles_cliente_id
            INNER JOIN clientes c          ON pc.cliente_id           = c.cliente_id
            LEFT JOIN tf_catalogos or_cat ON or_cat.id_opcion = o.origen_recursos
            LEFT JOIN tf_catalogos ori_cat ON ori_cat.id_opcion = o.origen_operacion
            LEFT JOIN tf_catalogos dst_cat ON dst_cat.id_opcion = o.destino_operacion
            LEFT JOIN tf_catalogos ins_cat ON ins_cat.id_opcion = o.instrumento_monetario
            LEFT JOIN tf_catalogos inc_cat ON inc_cat.id_opcion = o.incremento_monto_vs_anterior
            LEFT JOIN tf_catalogos pag_cat ON pag_cat.id_opcion = o.pago_excedido
            WHERE pc.cliente_id = $1
              AND c.sofom_id    = $2
            ORDER BY o.emision_operacion DESC
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