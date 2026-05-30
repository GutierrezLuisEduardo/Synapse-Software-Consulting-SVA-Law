const Alerta = require('../models/alerta.model');
const ROLES = require('../config/roles');

exports.getAlertas = async (req, res) => {
    try {
        const sofomId = req.session.usuario.sofom_id;
        const alertasResult = await Alerta.fetchAll(sofomId);

        res.render('alertas/index', {
            usuario: req.session.usuario,
            activePage: 'alertas',
            alertas: alertasResult.rows,
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
        const sofomId = req.session.usuario.sofom_id;

        const alertaResult = await Alerta.fetchById(alertaId, sofomId);

        if (alertaResult.rows.length === 0) {
            return res.status(404).send('Alerta no encontrada');
        }

        const alerta = alertaResult.rows[0];
        let reporte = null;

        if (alerta.operacion_id) {
            const reporteResult = await Alerta.fetchReporteByOperacion(alerta.operacion_id, sofomId);
            reporte = reporteResult.rows[0] || null;
        }

        res.render('alertas/detalle', {
            usuario: req.session.usuario,
            activePage: 'alertas',
            alerta,
            reporte,
            esOficial: req.session.usuario.rol === ROLES.OFICIAL
        });
    } catch (error) {
        console.error(error);
        res.status(500).send('Error interno del servidor');
    }
};