const Cliente   = require('../models/cliente.model');
const Documento = require('../models/documento.model');
const Contrato  = require('../models/contrato.model');
const Operacion = require('../models/operacion.model');
const Alerta    = require('../models/alerta.model');
const ROLES     = require('../config/roles');

let catalogosCache = null;

async function getCatalogos() {
    if (catalogosCache) return catalogosCache;

    const tiposPersona = await Cliente.fetchTiposPersona();
    const paisOrigen = await Cliente.fetchCatalogo(3);
    const nacionalidad = await Cliente.fetchCatalogo(4);
    const domicilio = await Cliente.fetchCatalogo(5);
    const actEconomica = await Cliente.fetchCatalogo(9);
    const vinculadoGrupo = await Cliente.fetchCatalogo(10);
    const estadoCivil = await Cliente.fetchCatalogo(14);
    const dependientes = await Cliente.fetchCatalogo(15);
    const numeroHijos = await Cliente.fetchCatalogo(16);
    const nivelEstudios = await Cliente.fetchCatalogo(17);
    const tipoVivienda = await Cliente.fetchCatalogo(18);
    const tipoEmpleo = await Cliente.fetchCatalogo(19);
    const ingresos = await Cliente.fetchCatalogo(20);
    const valorPatrim = await Cliente.fetchCatalogo(23);
    const pertPartido = await Cliente.fetchCatalogo(24);
    const peps = await Cliente.fetchCatalogo(8);
    const edad = await Cliente.fetchCatalogo(12);

    catalogosCache = {
        tiposPersona: tiposPersona.rows,
        paisOrigen: paisOrigen.rows,
        nacionalidad: nacionalidad.rows,
        domicilio: domicilio.rows,
        actividadEconomica: actEconomica.rows,
        vinculadoGrupo: vinculadoGrupo.rows,
        estadoCivil: estadoCivil.rows,
        dependientesEconomicos: dependientes.rows,
        numeroHijos: numeroHijos.rows,
        nivelEstudios: nivelEstudios.rows,
        tipoVivienda: tipoVivienda.rows,
        tipoEmpleo: tipoEmpleo.rows,
        ingresosMensuales: ingresos.rows,
        valorPatrimonio: valorPatrim.rows,
        pertenecePartido: pertPartido.rows,
        peps: peps.rows,
        edad: edad.rows,
    };

    return catalogosCache;
}

exports.warmCatalogos = () => getCatalogos().catch(console.error);

exports.getClientes = async (req, res) => {
    try {
        const limit = 50;
        const page = parseInt(req.query.page) || 1;
        const search = req.query.search || '';
        const offset = (page - 1) * limit;
        const sofomId = req.session.usuario.sofom_id;

        const [clientesDB, totalClientesDB] = await Promise.all([
            Cliente.fetchPaginated(limit, offset, search, sofomId),
            Cliente.count(search, sofomId),
        ]);

        const clientes     = clientesDB.rows;
        const totalClientes = parseInt(totalClientesDB.rows[0].total);
        const totalPages   = Math.ceil(totalClientes / limit);

        res.render('clientes/index', {
            usuario: req.session.usuario,
            activePage: 'clientes',
            clientes,
            currentPage: page,
            totalPages,
            search,
        });
    } catch (error) {
        console.error(error);
        res.status(500).send('Error interno del servidor');
    }
};

exports.getExpedienteCliente = async (req, res) => {
    try {
        const clienteId = req.params.id;
        const sofomId = req.session.usuario.sofom_id;

        const perteneceCheck = await Cliente.fetchByIdAndSofom(clienteId, sofomId);
        if (perteneceCheck.rows.length === 0) {
            return res.status(403).render('error/403', { usuario: req.session.usuario });
        }

        const [clienteDB, documentosDB, contratosDB, operacionesDB, alertasDB] = await Promise.all([
            Cliente.fetchById(clienteId),
            Documento.fetchByClienteId(clienteId),
            Contrato.fetchByClienteId(clienteId),
            Operacion.fetchByClienteId(clienteId, sofomId),
            Alerta.fetchByClienteId(clienteId, sofomId),
        ]);

        if (clienteDB.rows.length === 0) {
            return res.status(404).send('Cliente no encontrado');
        }

        const catalogos = await getCatalogos();
        const catalogosContrato = {
            canales: (await Contrato.fetchCatalogo(1)).rows,
            productos: (await Contrato.fetchCatalogo(2)).rows,
            finalidades: (await Contrato.fetchCatalogo(11)).rows,
            frecuenciasPago: (await Contrato.fetchCatalogo(21)).rows
        };

        // Calcular ponderaciones EBR para la vista de riesgo
        const cliente = clienteDB.rows[0];
        let ponderacionCliente = null;
        let ponderacionMonitoreo = null;

        if (cliente.enfoque_riesgos) {
            const enfoque = typeof cliente.enfoque_riesgos === 'string'
                ? JSON.parse(cliente.enfoque_riesgos)
                : cliente.enfoque_riesgos;

            // catalogo_ids 1-18 corresponden a campos de "Clasificación Cliente"
            // catalogo_ids 19-31 a "Clasificación Monitoreo"
            const idsCliente    = ['3','4','5','6','9','13','14','15','16','17','18','19','20','22','8','12','26','25'];
            const idsMonitoreo  = ['1','2','7','10','11','21','23','24','27','28','29','30','31'];

            ponderacionCliente   = idsCliente.reduce((s, k)  => s + (parseFloat(enfoque[k]) || 0), 0);
            ponderacionMonitoreo = idsMonitoreo.reduce((s, k) => s + (parseFloat(enfoque[k]) || 0), 0);
        }

        res.render('clientes/expediente', {
            usuario: req.session.usuario,
            activePage: 'clientes',
            cliente: clienteDB.rows[0],
            documentos: documentosDB.rows,
            contratos: contratosDB.rows,
            operaciones: operacionesDB.rows,
            alertas: alertasDB.rows,
            catalogos,
            catalogosContrato,
            ponderacionCliente,
            ponderacionMonitoreo,
        });
    } catch (error) {
        console.error(error);
        res.status(500).send('Error interno del servidor');
    }
};

exports.getAltaCliente = async (req, res) => {
    try {
        const catalogos  = await getCatalogos();
        const esEmpleado = [ROLES.EMPLEADO, ROLES.OFICIAL, ROLES.ADMIN].includes(req.session.usuario.rol);

        res.render('clientes/alta', {
            usuario: req.session.usuario,
            activePage: 'alta',
            esEmpleado,
            error: null,
            exito: req.query.exito ? 'Cliente registrado exitosamente' : null,
            catalogos,
            valores: null
        });
    } catch (error) {
        console.error('Error en getAltaCliente:', error.message);
        res.status(500).send(`Error: ${error.message}`);
    }
};

exports.postAltaCliente = async (req, res) => {
    const sofomId = req.session.usuario.sofom_id;
    const esEmpleado = [ROLES.EMPLEADO, ROLES.OFICIAL, ROLES.ADMIN].includes(req.session.usuario.rol);

    const renderConError = async (msg) => {
        const catalogos = await getCatalogos();
        return res.render('clientes/alta', {
            usuario: req.session.usuario,
            activePage: 'alta',
            esEmpleado,
            error: msg,
            exito: null,
            catalogos,
            valores: req.body
        });
    };

    try {
        const {
            razon_social, telefono, correo_electronico, clabe,
            serie_efirma, geolocalizacion, id_tipo_persona,
            curp, rfc, genero, fecha_nacimiento, pais_nacimiento,
            entidad_federativa_nacimiento, nombre_apoderado_legal, fecha_constitucion,
            pais_origen, nacionalidad, domicilio, actividad_economica,
            vinculado_con_grupo, estado_civil, dependientes_economicos,
            numero_hijos, nivel_estudios, tipo_vivienda, tipo_empleo,
            ingresos_mensuales, valor_patrimonio, pertenece_partido_politico,
            peps, edad,
        } = req.body;

        if (!razon_social || !telefono || !correo_electronico || !clabe ||
            !serie_efirma || !geolocalizacion || !pais_origen || !nacionalidad ||
            !domicilio || !actividad_economica || !vinculado_con_grupo ||
            !estado_civil || !dependientes_economicos || !numero_hijos ||
            !nivel_estudios || !tipo_vivienda || !tipo_empleo ||
            !ingresos_mensuales || !valor_patrimonio || !pertenece_partido_politico) {
            return renderConError('Todos los campos obligatorios deben estar completos');
        }

        if (clabe.length !== 18) {
            return renderConError('La CLABE debe tener exactamente 18 dígitos');
        }

        const nuevoCliente = await Cliente.create({
            sofom_id: sofomId,
            razon_social, telefono, correo_electronico, clabe,
            serie_efirma, geolocalizacion, id_tipo_persona: id_tipo_persona || 0,
            curp, rfc, genero, fecha_nacimiento, pais_nacimiento,
            entidad_federativa_nacimiento, nombre_apoderado_legal, fecha_constitucion,
            pais_origen, nacionalidad, domicilio, actividad_economica,
            vinculado_con_grupo, estado_civil, dependientes_economicos,
            numero_hijos, nivel_estudios, tipo_vivienda, tipo_empleo,
            ingresos_mensuales, valor_patrimonio, pertenece_partido_politico,
            peps, edad,
        });

        const clienteId = nuevoCliente.rows[0].cliente_id;
        await Cliente.crearPerfil(clienteId, sofomId);

        res.redirect('/clientes/alta?exito=1');

    } catch (error) {
        console.error(error);
        return renderConError('Error interno al guardar el cliente');
    }
};

exports.verificarCliente = async (req, res) => {
    try {
        const clienteId = parseInt(req.params.id);
        const sofomId = req.session.usuario.sofom_id;

        const result = await Cliente.fetchPerfilByClienteIdAndSofom(clienteId, sofomId);

        if (result.rows.length) {
            return res.json({ existe: true, nombre: result.rows[0].razon_social });
        }
        return res.json({ existe: false });
    } catch (err) {
        console.error('verificarCliente:', err);
        return res.status(500).json({ existe: false });
    }
};

exports.buscarClientes = async (req, res) => {
    try {
        const termino = (req.query.q || '').trim();
        const sofomId = req.session.usuario.sofom_id;

        if (!termino || termino.length < 1) {
            return res.json({ ok: true, clientes: [] });
        }

        const result = await Cliente.buscarPorTermino(termino, sofomId);
        return res.json({ ok: true, clientes: result.rows });
    } catch (err) {
        console.error('buscarClientes:', err);
        return res.status(500).json({ ok: false, clientes: [] });
    }
};

exports.postActualizarPerfilCliente = async (req, res) => {
    try {

        const clienteId = req.params.id;

        await Cliente.updateCatalogos(
            clienteId,
            req.body
        );

        await Cliente.marcarUltimoCambio(clienteId);

        return res.redirect(`/clientes/${clienteId}?actualizado=1`);

    } catch (err) {
        console.error(err);
        return res.status(500).send('Error al actualizar perfil');
    }
};

exports.postActualizarContrato = async (req, res) => {
    try {
        const clienteId = req.params.id;
        const {
            contrato_id,
            canal,
            producto,
            finalidad_credito,
            frecuencia_pago
        } = req.body;

        if (!contrato_id || !canal || !producto || !finalidad_credito || !frecuencia_pago) {
            return res.status(400).send('Faltan campos obligatorios del contrato');
        }

        await Contrato.updateCatalogos(
            parseInt(contrato_id),
            parseInt(canal),
            parseInt(producto),
            parseInt(finalidad_credito),
            parseInt(frecuencia_pago)
        );

        await Cliente.marcarPerfilActualizado(clienteId);
        await Cliente.marcarUltimoCambio(clienteId);

        return res.redirect(`/clientes/${clienteId}?actualizado=1`);

    } catch (err) {
        console.error('postActualizarContrato:', err);
        return res.status(500).send('Error actualizando contrato');
    }
};