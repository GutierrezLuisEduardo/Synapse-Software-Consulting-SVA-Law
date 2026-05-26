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
};