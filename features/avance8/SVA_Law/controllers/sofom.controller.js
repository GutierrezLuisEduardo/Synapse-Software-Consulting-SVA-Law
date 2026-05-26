const Sofom = require('../models/sofom.model');

exports.getSofomes = async (req, res) => {
    try {
        const sofomesResult = await Sofom.fetchAll();
        res.render('sofomes/index', {
            usuario: req.session.usuario,
            activePage: 'sofomes',
            sofomes: sofomesResult.rows,
            error: null
        });
    } catch (error) {
        console.error(error);
        res.status(500).send('Error interno del servidor');
    }
};

exports.getDetalleSofom = async (req, res) => {
    try {
        const sofomId = req.params.id;
        const { sofom, usuarios } = await Sofom.fetchByIdWithUsuarios(sofomId);

        if (sofom.rows.length === 0) {
            return res.status(404).send('SOFOM no encontrada');
        }

        res.render('sofomes/detalle', {
            usuario: req.session.usuario,
            activePage: 'sofomes',
            sofom: sofom.rows[0],
            usuarios: usuarios.rows
        });
    } catch (error) {
        console.error(error);
        res.status(500).send('Error interno del servidor');
    }
};