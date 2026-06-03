const Operacion = require('../models/operacion.model');
const ROLES = require('../config/roles');

let catalogosCache = null;

async function getCatalogosOperacion() {
    if (catalogosCache) return catalogosCache;

    const [origenRecursos, origenOperacion, destinoOperacion, instrumentoMonetario] =
        await Promise.all([
            Operacion.fetchCatalogo(13),
            Operacion.fetchCatalogo(6),
            Operacion.fetchCatalogo(7),
            Operacion.fetchCatalogo(27),
        ]);

    catalogosCache = {
        origenRecursos: origenRecursos.rows,
        origenOperacion: origenOperacion.rows,
        destinoOperacion: destinoOperacion.rows,
        instrumentoMonetario: instrumentoMonetario.rows,
    };

    return catalogosCache;
}

exports.warmCatalogosOperacion = () => getCatalogosOperacion().catch(console.error);

exports.getOperaciones = async (req, res) => {
    try {
        const limit = 50;
        const page = parseInt(req.query.page) || 1;
        const offset = (page - 1) * limit;
        const sofomId = req.session.usuario.sofom_id;

        const [operacionesDB, totalDB] = await Promise.all([
            Operacion.fetchPaginated(limit, offset, sofomId),
            Operacion.count(sofomId),
        ]);

        const operaciones = operacionesDB.rows;
        const totalOps = parseInt(totalDB.rows[0].total);
        const totalPages = Math.ceil(totalOps / limit);

        res.render('operaciones/index', {
            usuario: req.session.usuario,
            activePage: 'operaciones',
            operaciones,
            currentPage: page,
            totalPages,
        });
    } catch (error) {
        console.error('Error en getOperaciones:', error);
        res.status(500).send('Error interno del servidor');
    }
};

exports.getDetalleOperacion = async (req, res) => {
    try {
        const operacionId = req.params.id;
        const sofomId = req.session.usuario.sofom_id;

        const result = await Operacion.fetchById(operacionId, sofomId);

        if (result.rows.length === 0) {
            return res.status(404).render('error/403', { usuario: req.session.usuario });
        }

        res.render('operaciones/detalle', {
            usuario: req.session.usuario,
            activePage: 'operaciones',
            operacion: result.rows[0],
        });
    } catch (error) {
        console.error('Error en getDetalleOperacion:', error);
        res.status(500).send('Error interno del servidor');
    }
};

exports.getAltaOperacion = async (req, res) => {
    try {
        const catalogos = await getCatalogosOperacion();
        const puedeEditar = [ROLES.EMPLEADO, ROLES.OFICIAL, ROLES.ADMIN]
            .includes(req.session.usuario.rol);

        res.render('operaciones/alta', {
            usuario: req.session.usuario,
            activePage: 'alta-operacion',
            puedeEditar,
            catalogos,
            error: null,
            exito: req.query.exito ? 'Operación registrada exitosamente' : null,
            valores:null,
            contratos: [],
        });
    } catch (error) {
        console.error('Error en getAltaOperacion:', error);
        res.status(500).send(`Error: ${error.message}`);
    }
};

exports.postAltaOperacion = async (req, res) => {
    const sofomId = req.session.usuario.sofom_id;
    const puedeEditar = [ROLES.EMPLEADO, ROLES.OFICIAL, ROLES.ADMIN].includes(req.session.usuario.rol);

    const renderConError = async (msg, contratos = []) => {
        const catalogos = await getCatalogosOperacion();
        return res.render('operaciones/alta', {
            usuario: req.session.usuario,
            activePage: 'alta-operacion',
            puedeEditar,
            catalogos,
            error: msg,
            exito: null,
            valores: req.body,
            contratos,
        });
    };

    try {
        const {
            cliente_id, contrato_id, monto, emision_operacion,
            origen_recursos, origen_operacion, destino_operacion,
            instrumento_monetario,
        } = req.body;

        if (!cliente_id || !contrato_id || !monto || !emision_operacion ||
            !origen_recursos || !origen_operacion || !destino_operacion ||
            !instrumento_monetario) {
            const contratosDB = cliente_id
                ? await Operacion.fetchContratosDeCliente(cliente_id, sofomId)
                : { rows: [] };
            return renderConError('Todos los campos son obligatorios', contratosDB.rows);
        }

        const montoNum = parseFloat(monto);
        if (isNaN(montoNum) || montoNum <= 0) {
            return renderConError('El monto debe ser un número positivo');
        }

        const contratosDB = await Operacion.fetchContratosDeCliente(cliente_id, sofomId);
        const contratoValido = contratosDB.rows.some(c => String(c.contrato_id) === String(contrato_id));

        if (!contratoValido) {
            return renderConError('El contrato seleccionado no es válido para este cliente',contratosDB.rows);
        }

        const resultado = await Operacion.create({
            contrato_id, monto: montoNum, emision_operacion,
            origen_recursos, origen_operacion, destino_operacion,
            instrumento_monetario,
        });

        const nuevaOperacionId = resultado.rows[0].operacion_id;
        await Operacion.updateUltimaOperacion(contrato_id, nuevaOperacionId);

        res.redirect('/operaciones/alta?exito=1');

    } catch (error) {
        console.error('Error en postAltaOperacion:', error);
        return renderConError('Error interno al guardar la operación');
    }
};

exports.getContratosPorCliente = async (req, res) => {
    try {
        const clienteId = parseInt(req.params.clienteId);
        const sofomId   = req.session.usuario.sofom_id;

        const result = await Operacion.fetchContratosDeCliente(clienteId, sofomId);
        res.json({ ok: true, contratos: result.rows });
    } catch (error) {
        console.error('Error en getContratosPorCliente:', error);
        res.status(500).json({ ok: false, contratos: [] });
    }
};