const db = require('../util/database');



module.exports = class Operacion {

    static _buildFiltros(sofomId, filtros = {}) {
        const conds  = ['c.sofom_id = $1'];
        const params = [sofomId];
        let i = 2;

        const igual = (campo, valor) => {
            if (valor !== undefined && valor !== null && valor !== '') {
                conds.push(`o.${campo} = $${i++}`);
                params.push(parseInt(valor));
            }
        };

        igual('origen_recursos', filtros.origen_recursos);
        igual('origen_operacion', filtros.origen_operacion);
        igual('destino_operacion', filtros.destino_operacion);
        igual('instrumento_monetario', filtros.instrumento_monetario);
        igual('incremento_monto_vs_anterior', filtros.incremento_monto_vs_anterior);
        igual('pago_excedido', filtros.pago_excedido);

        if (filtros.monto_min !== undefined && filtros.monto_min !== '') {
            conds.push(`o.monto >= $${i++}`);
            params.push(parseFloat(filtros.monto_min));
        }
        if (filtros.monto_max !== undefined && filtros.monto_max !== '') {
            conds.push(`o.monto <= $${i++}`);
            params.push(parseFloat(filtros.monto_max));
        }

        return { whereSql: conds.join(' AND '), params };
    }


    static async fetchPaginated(limit, offset, sofomId, filtros = {}) {
        const { whereSql, params } = Operacion._buildFiltros(sofomId, filtros);
        const limitIdx  = params.length + 1;
        const offsetIdx = params.length + 2;
        params.push(limit, offset);

        const query = `
            SELECT
                o.operacion_id,
                o.contrato_id,
                o.monto,
                o.emision_operacion,
                c.cliente_id,
                c.razon_social        AS nombre_cliente,
                cat_or.opciones       AS origen_recursos,
                cat_ori.opciones      AS origen_operacion,
                cat_dst.opciones      AS destino_operacion,
                cat_ins.opciones      AS instrumento_monetario,
                cat_inc.opciones      AS incremento_monto_vs_anterior,
                cat_pag.opciones      AS pago_excedido
            FROM operaciones o
            INNER JOIN contratos ct        ON o.contrato_id          = ct.contrato_id
            INNER JOIN perfiles_cliente pc ON ct.perfiles_cliente_id = pc.perfiles_cliente_id
            INNER JOIN clientes c          ON pc.cliente_id          = c.cliente_id
            LEFT JOIN tf_catalogos cat_or  ON cat_or.id_opcion  = o.origen_recursos
            LEFT JOIN tf_catalogos cat_ori ON cat_ori.id_opcion = o.origen_operacion
            LEFT JOIN tf_catalogos cat_dst ON cat_dst.id_opcion = o.destino_operacion
            LEFT JOIN tf_catalogos cat_ins ON cat_ins.id_opcion = o.instrumento_monetario
            LEFT JOIN tf_catalogos cat_inc ON cat_inc.id_opcion = o.incremento_monto_vs_anterior
            LEFT JOIN tf_catalogos cat_pag ON cat_pag.id_opcion = o.pago_excedido
            WHERE ${whereSql}
            ORDER BY o.operacion_id ASC
            LIMIT $${limitIdx} OFFSET $${offsetIdx}
        `;
        return db.query(query, params);
    }

    static async count(sofomId, filtros = {}) {
        const { whereSql, params } = Operacion._buildFiltros(sofomId, filtros);
        const query = `
            SELECT COUNT(*) AS total
            FROM operaciones o
            INNER JOIN contratos ct ON o.contrato_id = ct.contrato_id
            INNER JOIN perfiles_cliente pc ON ct.perfiles_cliente_id = pc.perfiles_cliente_id
            INNER JOIN clientes c ON pc.cliente_id = c.cliente_id
            WHERE ${whereSql}
        `;
        return db.query(query, params);
    }

    static async fetchById(operacionId, sofomId) {
        const query = `
            SELECT
                o.operacion_id,
                o.contrato_id,
                o.monto,
                o.emision_operacion,
                o.es_moneda_extranjera,
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

    static async fetchAllForExport(sofomId, filtros = {}) {
        const { whereSql, params } = Operacion._buildFiltros(sofomId, filtros);
        const query = `
            SELECT
                o.operacion_id, o.contrato_id, c.cliente_id,
                c.razon_social  AS nombre_cliente,
                c.rfc           AS rfc_cliente,
                ct.descripcion  AS contrato_descripcion,
                s.razon_social  AS sofom_nombre,
                o.monto, o.es_moneda_extranjera, o.emision_operacion,
                cat_or.opciones  AS origen_recursos,
                cat_ori.opciones AS origen_operacion,
                cat_dst.opciones AS destino_operacion,
                cat_ins.opciones AS instrumento_monetario,
                cat_inc.opciones AS incremento_monto_vs_anterior,
                cat_pag.opciones AS pago_excedido
            FROM operaciones o
            INNER JOIN contratos ct        ON o.contrato_id          = ct.contrato_id
            INNER JOIN perfiles_cliente pc ON ct.perfiles_cliente_id = pc.perfiles_cliente_id
            INNER JOIN clientes c          ON pc.cliente_id          = c.cliente_id
            INNER JOIN sofom s             ON c.sofom_id             = s.sofom_id
            LEFT JOIN tf_catalogos cat_or  ON cat_or.id_opcion  = o.origen_recursos
            LEFT JOIN tf_catalogos cat_ori ON cat_ori.id_opcion = o.origen_operacion
            LEFT JOIN tf_catalogos cat_dst ON cat_dst.id_opcion = o.destino_operacion
            LEFT JOIN tf_catalogos cat_ins ON cat_ins.id_opcion = o.instrumento_monetario
            LEFT JOIN tf_catalogos cat_inc ON cat_inc.id_opcion = o.incremento_monto_vs_anterior
            LEFT JOIN tf_catalogos cat_pag ON cat_pag.id_opcion = o.pago_excedido
            WHERE ${whereSql}
            ORDER BY o.emision_operacion ASC, o.operacion_id ASC
        `;
        return db.query(query, params);
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
        es_moneda_extranjera
    }) {
        const query = `
            INSERT INTO operaciones (
                contrato_id,
                monto,
                emision_operacion,
                origen_recursos,
                origen_operacion,
                destino_operacion,
                instrumento_monetario,
                es_moneda_extranjera
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
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
            es_moneda_extranjera
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