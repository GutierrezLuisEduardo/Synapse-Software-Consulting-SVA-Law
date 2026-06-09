const db = require('../util/database');

module.exports = class Contrato {

    static async fetchByClienteId(clienteId) {
        const query = `
            WITH cts AS (
                SELECT
                    c.contrato_id,
                    c.descripcion,
                    c.fecha_inicio,
                    c.fecha_finalizacion,
                    c.monto_total_pago,
                    c.monto_pagado,
                    c.pago_por_operacion,
                    c.numero_pagos_acordados,
                    c.numero_pagos_hechos,
                    c.canal,
                    c.producto,
                    c.frecuencia_pago
                FROM contratos c
                INNER JOIN perfiles_cliente pc ON pc.perfiles_cliente_id = c.perfiles_cliente_id
                WHERE pc.cliente_id = $1
            ),
            ids AS (
                SELECT DISTINCT unnest(ARRAY[canal, producto, frecuencia_pago]) AS id_opcion
                FROM cts
            ),
            cat AS (
                SELECT tc.id_opcion, tc.opciones
                FROM tf_catalogos tc
                INNER JOIN ids ON tc.id_opcion = ids.id_opcion
            )
            SELECT
                cts.contrato_id,
                cts.descripcion,
                cts.fecha_inicio,
                cts.fecha_finalizacion,
                cts.monto_total_pago,
                cts.monto_pagado,
                cts.pago_por_operacion,
                cts.numero_pagos_acordados,
                cts.numero_pagos_hechos,
                can_cat.opciones  AS canal,
                prod_cat.opciones AS producto,
                fp_cat.opciones   AS frecuencia_pago
            FROM cts
            LEFT JOIN cat can_cat  ON can_cat.id_opcion  = cts.canal
            LEFT JOIN cat prod_cat ON prod_cat.id_opcion = cts.producto
            LEFT JOIN cat fp_cat   ON fp_cat.id_opcion   = cts.frecuencia_pago
            ORDER BY cts.contrato_id ASC
        `;
        return db.query(query, [clienteId]);
    }

    static async create(perfilesClienteId, sofomId, descripcion, canal, producto,
                        finalidadCredito, frecuenciaPago, fechaInicio, fechaFinalizacion,
                        montoTotalPago) {
        const query = `
            INSERT INTO contratos (
                perfiles_cliente_id, sofom_id, id_ultima_operacion, descripcion,
                canal, producto, finalidad_credito, frecuencia_pago, frecuencia,
                numero_pagos_acordados, numero_pagos_hechos,
                liquidacion_anticipada_ultimo_pago,
                fecha_inicio, fecha_finalizacion, monto_total_pago
            ) VALUES (
                $1, $2, NULL, $3,
                $4, $5, $6, $7, 0,
                0, 0, 0,
                $8, $9, $10
            )
            RETURNING contrato_id
        `;
        return db.query(query, [
            perfilesClienteId, sofomId, descripcion,
            canal, producto, finalidadCredito, frecuenciaPago,
            fechaInicio, fechaFinalizacion, montoTotalPago
        ]);
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
};