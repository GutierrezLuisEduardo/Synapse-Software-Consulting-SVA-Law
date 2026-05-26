const Cliente = require('../models/cliente.model');
const Documento = require('../models/documento.model');
const Contrato = require('../models/contrato.model');
const ROLES = require('../config/roles');

exports.getClientes = async (req, res) => {
    try {
        const limit = 50;
        const page = parseInt(req.query.page) || 1;
        const search = req.query.search || '';
        const offset = (page - 1) * limit;
        const sofomId = req.session.usuario.sofom_id;

        const clientesDB = await Cliente.fetchPaginated(limit, offset, search, sofomId);
        const totalClientesDB = await Cliente.count(search, sofomId);
        const clientes = clientesDB.rows;
        const totalClientes = parseInt(totalClientesDB.rows[0].total);
        const totalPages = Math.ceil(totalClientes / limit);

        res.render('clientes/index', {
            usuario: req.session.usuario,
            activePage: 'clientes',
            clientes,
            currentPage: page,
            totalPages,
            search
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

        const [clienteDB, documentosDB, contratosDB] = await Promise.all([
            Cliente.fetchById(clienteId),
            Documento.fetchByClienteId(clienteId),
            Contrato.fetchByClienteId(clienteId)
        ]);

        if (clienteDB.rows.length === 0) {
            return res.status(404).send('Cliente no encontrado');
        }

        res.render('clientes/expediente', {
            usuario: req.session.usuario,
            activePage: 'clientes',
            cliente: clienteDB.rows[0],
            documentos: documentosDB.rows,
            contratos: contratosDB.rows
        });
    } catch (error) {
        console.error(error);
        res.status(500).send('Error interno del servidor');
    }
};

exports.getAltaCliente = async (req, res) => {
    try {
        const [
            tiposPersona, paisOrigen, nacionalidad, domicilio, 
            actividadEconomica, vinculadoGrupo, estadoCivil,
            dependientesEconomicos, numeroHijos, nivelEstudios, tipoVivienda, 
            tipoEmpleo, ingresosMensuales, valorPatrimonio, pertenecePartido, 
            peps, edad
        ] = await Promise.all([
            Cliente.fetchTiposPersona(),
            Cliente.fetchCatalogo(3),  // País de origen
            Cliente.fetchCatalogo(4),  // Nacionalidad
            Cliente.fetchCatalogo(5),  // Domicilio
            Cliente.fetchCatalogo(9),  // Actividad Económica
            Cliente.fetchCatalogo(10), // Vinculado con grupo
            Cliente.fetchCatalogo(14), // Estado civil
            Cliente.fetchCatalogo(15), // Dependientes económicos
            Cliente.fetchCatalogo(16), // Número de hijos
            Cliente.fetchCatalogo(17), // Nivel de estudios
            Cliente.fetchCatalogo(18), // Tipo de vivienda
            Cliente.fetchCatalogo(19), // Tipo de empleo
            Cliente.fetchCatalogo(20), // Ingresos mensuales
            Cliente.fetchCatalogo(23), // Valor patrimonio
            Cliente.fetchCatalogo(24), // Pertenece a partido político
            Cliente.fetchCatalogo(8),  // PEPS
            Cliente.fetchCatalogo(12), // Edad
        ]);

        const esEmpleado = req.session.usuario.rol === ROLES.EMPLEADO;

        res.render('clientes/alta', {
            usuario: req.session.usuario,
            activePage: 'alta',
            esEmpleado,
            error: null,
            exito: null,
            catalogos: {
                tiposPersona: tiposPersona.rows,
                paisOrigen: paisOrigen.rows,
                nacionalidad: nacionalidad.rows,
                domicilio: domicilio.rows,
                actividadEconomica: actividadEconomica.rows,
                vinculadoGrupo: vinculadoGrupo.rows,
                estadoCivil: estadoCivil.rows,
                dependientesEconomicos: dependientesEconomicos.rows,
                numeroHijos: numeroHijos.rows,
                nivelEstudios: nivelEstudios.rows,
                tipoVivienda: tipoVivienda.rows,
                tipoEmpleo: tipoEmpleo.rows,
                ingresosMensuales: ingresosMensuales.rows,
                valorPatrimonio: valorPatrimonio.rows,
                pertenecePartido: pertenecePartido.rows,
                peps: peps.rows,
                edad: edad.rows
            }
        });
    } catch (error) {
        console.error('Error en getExpedienteCliente:', error.message);
        console.error('Query que falló:', error.query || 'desconocida');
        res.status(500).send(`Error: ${error.message}`);
    }
};

exports.postAltaCliente = async (req, res) => {
    const sofomId = req.session.usuario.sofom_id;

    const renderConError = async (msg) => {
        const [
            tiposPersona, paisOrigen, nacionalidad, domicilio,
            actividadEconomica, vinculadoGrupo, estadoCivil,
            dependientesEconomicos, numeroHijos, nivelEstudios,
            tipoVivienda, tipoEmpleo, ingresosMensuales,
            valorPatrimonio, pertenecePartido, peps, edad
        ] = await Promise.all([
            Cliente.fetchTiposPersona(),
            Cliente.fetchCatalogo(3), Cliente.fetchCatalogo(4), Cliente.fetchCatalogo(5),
            Cliente.fetchCatalogo(9), Cliente.fetchCatalogo(10), Cliente.fetchCatalogo(14),
            Cliente.fetchCatalogo(15), Cliente.fetchCatalogo(16), Cliente.fetchCatalogo(17),
            Cliente.fetchCatalogo(18), Cliente.fetchCatalogo(19), Cliente.fetchCatalogo(20),
            Cliente.fetchCatalogo(23), Cliente.fetchCatalogo(24), Cliente.fetchCatalogo(8),
            Cliente.fetchCatalogo(12)
        ]);

        return res.render('clientes/alta', {
            usuario: req.session.usuario,
            activePage: 'alta',
            esEmpleado: true,
            error: msg,
            exito: null,
            catalogos: {
                tiposPersona: tiposPersona.rows,
                paisOrigen: paisOrigen.rows,
                nacionalidad: nacionalidad.rows,
                domicilio: domicilio.rows,
                actividadEconomica: actividadEconomica.rows,
                vinculadoGrupo: vinculadoGrupo.rows,
                estadoCivil: estadoCivil.rows,
                dependientesEconomicos: dependientesEconomicos.rows,
                numeroHijos: numeroHijos.rows,
                nivelEstudios: nivelEstudios.rows,
                tipoVivienda: tipoVivienda.rows,
                tipoEmpleo: tipoEmpleo.rows,
                ingresosMensuales: ingresosMensuales.rows,
                valorPatrimonio: valorPatrimonio.rows,
                pertenecePartido: pertenecePartido.rows,
                peps: peps.rows,
                edad: edad.rows
            }
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
            peps, edad
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

        await Cliente.create({
            sofom_id: sofomId,
            razon_social, telefono, correo_electronico, clabe,
            serie_efirma, geolocalizacion, id_tipo_persona: id_tipo_persona || 0,
            curp, rfc, genero, fecha_nacimiento, pais_nacimiento,
            entidad_federativa_nacimiento, nombre_apoderado_legal, fecha_constitucion,
            pais_origen, nacionalidad, domicilio, actividad_economica,
            vinculado_con_grupo, estado_civil, dependientes_economicos,
            numero_hijos, nivel_estudios, tipo_vivienda, tipo_empleo,
            ingresos_mensuales, valor_patrimonio, pertenece_partido_politico,
            peps, edad
        });

        const [
            tiposPersona, paisOrigenR, nacionalidadR, domicilioR,
            actividadEconomicaR, vinculadoGrupoR, estadoCivilR,
            dependientesEconomicosR, numeroHijosR, nivelEstudiosR,
            tipoViviendaR, tipoEmpleoR, ingresosMensualesR,
            valorPatrimonioR, pertenecePartidoR, pepsR, edadR
        ] = await Promise.all([
            Cliente.fetchTiposPersona(),
            Cliente.fetchCatalogo(3), Cliente.fetchCatalogo(4), Cliente.fetchCatalogo(5),
            Cliente.fetchCatalogo(9), Cliente.fetchCatalogo(10), Cliente.fetchCatalogo(14),
            Cliente.fetchCatalogo(15), Cliente.fetchCatalogo(16), Cliente.fetchCatalogo(17),
            Cliente.fetchCatalogo(18), Cliente.fetchCatalogo(19), Cliente.fetchCatalogo(20),
            Cliente.fetchCatalogo(23), Cliente.fetchCatalogo(24), Cliente.fetchCatalogo(8),
            Cliente.fetchCatalogo(12)
        ]);

        res.render('clientes/alta', {
            usuario: req.session.usuario,
            activePage: 'alta',
            esEmpleado: true,
            error: null,
            exito: `Cliente "${razon_social}" registrado exitosamente`,
            catalogos: {
                tiposPersona: tiposPersona.rows,
                paisOrigen: paisOrigenR.rows,
                nacionalidad: nacionalidadR.rows,
                domicilio: domicilioR.rows,
                actividadEconomica: actividadEconomicaR.rows,
                vinculadoGrupo: vinculadoGrupoR.rows,
                estadoCivil: estadoCivilR.rows,
                dependientesEconomicos: dependientesEconomicosR.rows,
                numeroHijos: numeroHijosR.rows,
                nivelEstudios: nivelEstudiosR.rows,
                tipoVivienda: tipoViviendaR.rows,
                tipoEmpleo: tipoEmpleoR.rows,
                ingresosMensuales: ingresosMensualesR.rows,
                valorPatrimonio: valorPatrimonioR.rows,
                pertenecePartido: pertenecePartidoR.rows,
                peps: pepsR.rows,
                edad: edadR.rows
            }
        });

    } catch (error) {
        console.error(error);
        return renderConError('Error interno al guardar el cliente');
    }
};