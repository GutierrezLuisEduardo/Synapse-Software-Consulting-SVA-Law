const Operacion = require('../models/operacion.model');
const ROLES = require('../config/roles');

let catalogosCache = null;

async function getCatalogosOperacion() {
    if (catalogosCache) return catalogosCache;

    const [origenRecursos, origenOperacion, destinoOperacion,
           instrumentoMonetario, pagoExcedido, incrementoMonto] =
        await Promise.all([
            Operacion.fetchCatalogo(13),
            Operacion.fetchCatalogo(6),
            Operacion.fetchCatalogo(7),
            Operacion.fetchCatalogo(27),
            Operacion.fetchCatalogo(28),
            Operacion.fetchCatalogo(31),
        ]);

    catalogosCache = {
        origenRecursos: origenRecursos.rows,
        origenOperacion: origenOperacion.rows,
        destinoOperacion: destinoOperacion.rows,
        instrumentoMonetario: instrumentoMonetario.rows,
        pagoExcedido: pagoExcedido.rows,
        incrementoMonto: incrementoMonto.rows,
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

        const filtros = {
            origen_recursos: req.query.origen_recursos || '',
            origen_operacion: req.query.origen_operacion || '',
            destino_operacion: req.query.destino_operacion || '',
            instrumento_monetario: req.query.instrumento_monetario || '',
            incremento_monto_vs_anterior: req.query.incremento_monto_vs_anterior || '',
            pago_excedido: req.query.pago_excedido || '',
            monto_min: req.query.monto_min || '',
            monto_max: req.query.monto_max || '',
        };

        const [catalogos, operacionesDB, totalDB] = await Promise.all([
            getCatalogosOperacion(),
            Operacion.fetchPaginated(limit, offset, sofomId, filtros),
            Operacion.count(sofomId, filtros),
        ]);

        const operaciones = operacionesDB.rows;
        const totalOps    = parseInt(totalDB.rows[0].total);
        const totalPages  = Math.ceil(totalOps / limit);

        const queryParams = new URLSearchParams();
        Object.entries(filtros).forEach(([k, v]) => { if (v) queryParams.append(k, v); });
        const queryFiltros = queryParams.toString();

        res.render('operaciones/index', {
            usuario: req.session.usuario,
            activePage: 'operaciones',
            operaciones,
            currentPage: page,
            totalPages,
            catalogos,
            filtros,
            queryFiltros,
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
            instrumento_monetario, es_moneda_extranjera
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

        const esMonedaExtranjera = es_moneda_extranjera === 'true';

        const resultado = await Operacion.create({
            contrato_id, 
            monto: montoNum, 
            emision_operacion,
            origen_recursos, 
            origen_operacion, 
            destino_operacion,
            instrumento_monetario,
            es_moneda_extranjera: esMonedaExtranjera
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

exports.exportarHistorial = async (req, res) => {
    try {
        const sofomId = req.session.usuario.sofom_id;
        const usuario = req.session.usuario;

        const filtros = {
            origen_recursos: req.query.origen_recursos || '',
            origen_operacion: req.query.origen_operacion || '',
            destino_operacion: req.query.destino_operacion || '',
            instrumento_monetario: req.query.instrumento_monetario || '',
            incremento_monto_vs_anterior: req.query.incremento_monto_vs_anterior || '',
            pago_excedido: req.query.pago_excedido || '',
            monto_min: req.query.monto_min || '',
            monto_max: req.query.monto_max || '',
        };

        const { rows } = await Operacion.fetchAllForExport(sofomId, filtros);

        // --- Helpers de formato ---
        const pad = (txt, len) => {
            const s = (txt === null || txt === undefined ? '' : String(txt));
            return s.length >= len ? s.slice(0, len) : s + ' '.repeat(len - s.length);
        };
        const fmtMonto = (m) =>
            '$' + Number(m).toLocaleString('es-MX', { minimumFractionDigits: 2 });
        const fmtFecha = (d) => {
            if (!d) return '—';
            const fecha = new Date(d);
            return fecha.toLocaleString('es-MX', {
                year: 'numeric', month: '2-digit', day: '2-digit',
                hour: '2-digit', minute: '2-digit'
            });
        };

        const lineas = [];
        const sep = '='.repeat(160);
        const subsep = '-'.repeat(160);
        const ahora = new Date().toLocaleString('es-MX');
        const sofomNombre = rows.length ? rows[0].sofom_nombre : '—';

        lineas.push(sep);
        lineas.push('  HISTORIAL DE OPERACIONES');
        lineas.push(`  SOFOM:        ${sofomNombre}`);
        lineas.push(`  Generado por: ${usuario.nombre || usuario.correo_electronico || ('usuario_' + usuario.usuario_id)}`);
        lineas.push(`  Fecha:        ${ahora}`);
        lineas.push(`  Total ops:    ${rows.length}`);
        lineas.push(sep);
        lineas.push('');

        if (rows.length === 0) {
            lineas.push('  No hay operaciones registradas para esta SOFOM.');
        } else {
            const header =
                pad('ID OP', 8) +
                pad('ID CONTRATO', 13) +
                pad('CLIENTE', 32) +
                pad('RFC', 14) +
                pad('MONTO', 18) +
                pad('M/E', 5) +
                pad('INSTRUMENTO', 22) +
                pad('ORIGEN RECURSOS', 22) +
                pad('PAGO EXCEDIDO', 16) +
                pad('FECHA', 18);
            lineas.push(header);
            lineas.push(subsep);

            let totalMonto = 0;
            rows.forEach(op => {
                totalMonto += Number(op.monto || 0);
                lineas.push(
                    pad(op.operacion_id, 8) +
                    pad(op.contrato_id, 13) +
                    pad(op.nombre_cliente, 32) +
                    pad(op.rfc_cliente || '—', 14) +
                    pad(fmtMonto(op.monto), 18) +
                    pad(op.es_moneda_extranjera ? 'Sí' : 'No', 5) +
                    pad(op.instrumento_monetario || '—', 22) +
                    pad(op.origen_recursos || '—', 22) +
                    pad(op.pago_excedido || '—', 16) +
                    pad(fmtFecha(op.emision_operacion), 18)
                );
            });

            lineas.push(subsep);
            lineas.push(
                pad('', 8 + 13 + 32 + 14) +
                pad(fmtMonto(totalMonto), 18) +
                '   <- Monto total'
            );
        }

        lineas.push('');
        lineas.push(sep);
        lineas.push('  Fin del reporte');
        lineas.push(sep);

        const contenido = lineas.join('\n');

        const fechaArchivo = new Date().toISOString().replace(/[:T]/g, '-').slice(0, 16);
        const nombreArchivo = `historial_operaciones_${fechaArchivo}.txt`;

        res.setHeader('Content-Type', 'text/plain; charset=utf-8');
        res.setHeader('Content-Disposition', `attachment; filename="${nombreArchivo}"`);
        // BOM UTF-8 para que abra correctamente con acentos en Bloc de notas / Excel
        return res.send('\uFEFF' + contenido);

    } catch (error) {
        console.error('Error en exportarHistorial:', error);
        return res.status(500).send('Error al exportar el historial');
    }
};