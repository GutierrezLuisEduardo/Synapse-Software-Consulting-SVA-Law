const Alerta = require('../models/alerta.model');
const ROLES = require('../config/roles');
const db = require('../util/database');


exports.getAlertas = async (req, res) => {
    try {
        const sofomId = req.session.usuario.sofom_id;
        const rol = req.session.usuario.rol;
        const { tipo_alerta_id, tipo_reporte_id } = req.query;

        // Solo el Oficial de cumplimiento puede ver ROIP
        const soloROIP = rol === ROLES.OFICIAL ? null : false;

        const [alertasResult, tiposAlertaResult, tiposReporteResult] = await Promise.all([
            Alerta.fetchAllFiltrado(sofomId, tipo_alerta_id || null, tipo_reporte_id || null, soloROIP),
            db.query('SELECT tipo_alerta_id, descripcion FROM tf_tipos_alerta ORDER BY tipo_alerta_id'),
            db.query('SELECT tipo_reporte_id, descripcion FROM tf_tipos_reporte ORDER BY tipo_reporte_id')
        ]);

        res.render('alertas/index', {
            usuario: req.session.usuario,
            activePage: 'alertas',
            alertas: alertasResult.rows,
            tiposAlerta: tiposAlertaResult.rows,
            tiposReporte: tiposReporteResult.rows,
            filtros: { tipo_alerta_id: tipo_alerta_id || '', tipo_reporte_id: tipo_reporte_id || '' },
            esOficial: rol === ROLES.OFICIAL,
            puedeEmitirDictamen: [ROLES.OFICIAL, ROLES.ADMIN].includes(rol),
            error: null
        });
    } catch (error) {
        console.error(error);
        res.status(500).send('Error interno del servidor');
    }
};

exports.getDetalleAlerta = async (req, res) => {
    try {
        const alertaId = req.params.id;
        const sofomId  = req.session.usuario.sofom_id;
        const rol = req.session.usuario.rol;

        const alertaResult = await Alerta.fetchById(alertaId, sofomId);
        if (alertaResult.rows.length === 0) return res.status(404).send('Alerta no encontrada');

        const alerta = alertaResult.rows[0];

        // Bloquear ROIP a no-oficiales
        if (alerta.tipo_reporte_id === 3 && rol !== ROLES.OFICIAL) {
            return res.status(403).render('error/403', { usuario: req.session.usuario });
        }

        let reporte = null;
        if (alerta.reporte_id) {
            const r = await Alerta.fetchReporteById(alerta.reporte_id, sofomId);
            reporte = r.rows[0] || null;
        } else if (alerta.operacion_id) {
            const r = await Alerta.fetchReporteByOperacion(alerta.operacion_id, sofomId);
            reporte = r.rows[0] || null;
        }

        res.render('alertas/detalle', {
            usuario:   req.session.usuario,
            activePage:'alertas',
            alerta,
            reporte,
            esOficial: rol === ROLES.OFICIAL,
            puedeEmitirDictamen: [ROLES.OFICIAL, ROLES.ADMIN].includes(rol)
        });
    } catch (error) {
        console.error(error);
        res.status(500).send('Error interno del servidor');
    }
};



exports.postDictamen = async (req, res) => {
    try {
        const alertaId = req.params.id;
        const sofomId  = req.session.usuario.sofom_id;
        const rol      = req.session.usuario.rol;
        const { accion, descripcion_dictamen } = req.body;

        if (![ROLES.OFICIAL, ROLES.ADMIN].includes(rol)) {
            return res.status(403).render('error/403', { usuario: req.session.usuario });
        }

        if (!descripcion_dictamen?.trim()) {
            return res.status(400).send(
                'Debe capturarse un dictamen'
            );
        }

        const aprobado = accion === 'aprobar';
        await Alerta.emitirDictamen(alertaId, sofomId, aprobado, descripcion_dictamen);
        res.redirect(`/alertas/${alertaId}`);
    } catch (error) {
        console.error(error);
        res.status(500).send('Error interno del servidor');
    }
};

exports.getDescargarReportes = async (req, res) => {
    try {
        const sofomId = req.session.usuario.sofom_id;
        const result  = await Alerta.fetchReportesPendientesDescarga(sofomId);
        const reportes = result.rows;

        if (reportes.length === 0) {
            return res.redirect('/alertas?sin_reportes=1');
        }

        const ids = reportes.map(r => r.reporte_id);
        await Alerta.marcarDescargados(ids, sofomId);

        // Generar archivo de texto
        const lineas = reportes.map(r =>
            `--- Reporte #${r.reporte_id} (${r.tipo_reporte}) ---\n` +
            `Fecha: ${new Date(r.fecha_generacion).toLocaleString('es-MX')}\n` +
            `Asunto: ${r.asunto}\n` +
            `Descripción: ${r.descripcion}\n` +
            `Evidencia: ${r.evidencia || 'Sin evidencia'}\n`
        ).join('\n');

        res.setHeader('Content-Type', 'text/plain; charset=utf-8');
        res.setHeader('Content-Disposition', `attachment; filename="reportes_${Date.now()}.txt"`);
        res.send(lineas);
    } catch (error) {
        console.error(error);
        res.status(500).send('Error interno del servidor');
    }
};

exports.getExportarAlertas = async (req, res) => {
    try {
        const sofomId = req.session.usuario.sofom_id;
        const result  = await Alerta.fetchHistorialCompleto(sofomId);

        const lineas = result.rows.map(a =>
            `--- Alerta #${a.alerta_id} ---\n` +
            `Fecha: ${new Date(a.fecha_hora_alerta).toLocaleString('es-MX')}\n` +
            `Tipo alerta: ${a.tipo_alerta}\n` +
            `Tipo reporte: ${a.tipo_reporte}\n` +
            `Estado: ${a.estado_revision ? 'Revisada' : 'Pendiente'}\n` +
            `Aprobada: ${a.esta_aprobado ? 'Sí' : 'No'}\n` +
            `Descripción: ${a.descripcion}\n`
        ).join('\n');

        res.setHeader('Content-Type', 'text/plain; charset=utf-8');
        res.setHeader('Content-Disposition', `attachment; filename="historial_alertas_${Date.now()}.txt"`);
        res.send(lineas);
    } catch (error) {
        console.error(error);
        res.status(500).send('Error interno del servidor');
    }
};