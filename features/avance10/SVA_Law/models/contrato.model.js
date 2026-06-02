const db = require('../util/database');

module.exports = class Contrato {

    static async fetchByClienteId(clienteId) {
        const query = `
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
                can_cat.valores AS canal,
                prod_cat.valores AS producto,
                fp_cat.valores AS frecuencia_pago
            FROM contratos c
            INNER JOIN perfiles_cliente pc ON c.perfiles_cliente_id = pc.perfiles_cliente_id
            LEFT JOIN tf_catalogos can_cat ON can_cat.catalogo_id = c.canal
            LEFT JOIN tf_catalogos prod_cat ON prod_cat.catalogo_id = c.producto
            LEFT JOIN tf_catalogos fp_cat ON fp_cat.catalogo_id = c.frecuencia_pago
            WHERE pc.cliente_id = $1
            ORDER BY c.contrato_id ASC
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
                $1, $2, 0, $3,
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