const Contrato = require('../models/contrato.model');
const Cliente  = require('../models/cliente.model');
const ROLES    = require('../config/roles');

// IDs de catálogos según BD
// catalogo_id 1  = Canales
// catalogo_id 2  = Productos
// catalogo_id 11 = Finalidad/Destino del crédito
// catalogo_id 21 = Frecuencia de pago/ingresos

let catalogosCache = null;

async function getCatalogos() {
    if (catalogosCache) return catalogosCache;
    const [canales, productos, finalidades, frecuenciasPago] = await Promise.all([
        Contrato.fetchCatalogo(1),
        Contrato.fetchCatalogo(2),
        Contrato.fetchCatalogo(11),
        Contrato.fetchCatalogo(21)
    ]);
    catalogosCache = {
        canales: canales.rows,
        productos: productos.rows,
        finalidades: finalidades.rows,
        frecuenciasPago: frecuenciasPago.rows
    };
    return catalogosCache;
}

exports.warmCatalogosContrato = async () => {
    try { await getCatalogos(); }
    catch (e) { console.error('Error precargando catálogos de contrato:', e.message); }
};

exports.getAltaContrato = async (req, res) => {
    try {
        const catalogos = await getCatalogos();
        const puedeEditar = [ROLES.ADMIN, ROLES.OFICIAL, ROLES.EMPLEADO].includes(req.session.usuario.rol);

        return res.render('contratos/alta', {
            usuario: req.session.usuario,
            activePage: 'alta-contrato',
            catalogos,
            puedeEditar,
            exito: req.query.exito ? 'Contrato registrado correctamente.' : null,
            valores: null,
            error: null,
        });
    } catch (err) {
        console.error('getAltaContrato:', err);
        return res.status(500).send('Error interno del servidor.');
    }
};

exports.postAltaContrato = async (req, res) => {
    try {
        const {
            cliente_id, descripcion,
            canal, producto, finalidad_credito, frecuencia_pago,
            fecha_inicio, fecha_finalizacion, monto_total_pago
        } = req.body;

        const sofomId    = req.session.usuario.sofom_id;
        const catalogos  = await getCatalogos();
        const puedeEditar = [ROLES.ADMIN, ROLES.OFICIAL, ROLES.EMPLEADO].includes(req.session.usuario.rol);

        const renderError = (msg) => res.render('contratos/alta', {
            usuario: req.session.usuario,
            activePage: 'alta-contrato',
            catalogos,
            puedeEditar,
            valores: req.body,
            error: msg,
            exito: null
        });

        if (!cliente_id || !canal || !producto || !finalidad_credito ||
            !frecuencia_pago || !fecha_inicio || !fecha_finalizacion || !monto_total_pago) {
            return renderError('Todos los campos obligatorios deben completarse.');
        }

        const monto = parseFloat(monto_total_pago);
        if (isNaN(monto) || monto <= 0) {
            return renderError('El monto total de pago debe ser un número positivo.');
        }

        if (new Date(fecha_finalizacion) <= new Date(fecha_inicio)) {
            return renderError('La fecha de finalización debe ser posterior a la fecha de inicio.');
        }

        const perfilResult = await Cliente.fetchPerfilByClienteIdAndSofom(
            parseInt(cliente_id), sofomId
        );
        if (!perfilResult.rows.length) {
            return renderError('Cliente no encontrado en esta SOFOM.');
        }
        const perfilesClienteId = perfilResult.rows[0].perfiles_cliente_id;

        await Contrato.create(
            perfilesClienteId, sofomId, descripcion || null,
            parseInt(canal), parseInt(producto),
            parseInt(finalidad_credito), parseInt(frecuencia_pago),
            fecha_inicio, fecha_finalizacion, monto
        );

        return res.redirect('/contratos/alta?exito=1');

    } catch (err) {
        console.error('postAltaContrato:', err);
        return res.status(500).send('Error interno del servidor.');
    }
};