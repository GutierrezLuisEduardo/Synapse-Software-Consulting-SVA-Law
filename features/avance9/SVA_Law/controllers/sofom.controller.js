const Sofom = require('../models/sofom.model');

exports.getCreateSofom = async (req, res) => {
    try {
        const tiposEntidad = await Sofom.fetchTiposEntidad();

        res.render('sofomes/create', {
            usuario: req.session.usuario,
            activePage: 'create',
            error: null,
            tiposEntidad: tiposEntidad.rows
        });
    } catch (error) {
        console.error(error);
        res.status(500).send('Error interno del servidor');
    }
};

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
        const rol = req.session.usuario.rol;

        let sofom;
        let usuarios;

        if (rol === 'Root') {

            const sofomResult = await Sofom.fetchById(sofomId);

            if (sofomResult.rows.length === 0) {
                return res.status(404).send('SOFOM no encontrada');
            }

            sofom = sofomResult.rows[0];
            usuarios = [];

        } else {

            const result = await Sofom.fetchByIdWithUsuarios(sofomId);

            if (result.sofom.rows.length === 0) {
                return res.status(404).send('SOFOM no encontrada');
            }

            sofom = result.sofom.rows[0];
            usuarios = result.usuarios.rows;
        }

        res.render('sofomes/detalle', {
            usuario: req.session.usuario,
            activePage: 'sofomes',
            sofom,
            usuarios,
            esRoot: rol === 'Root'
        });

    } catch (error) {
        console.error(error);
        res.status(500).send('Error interno del servidor');
    }
};

exports.postCreateSofom = async (req, res) => {

    try {
        const {
            razon_social,
            tipo_entidad_id
        } = req.body;

        await Sofom.create(razon_social, tipo_entidad_id);
        res.redirect('/sofomes');

    } catch (error) {
        console.error(error);
        res.render('sofomes/create', {
            usuario: req.session.usuario,
            activePage: 'create',
            error: 'No se pudo crear la SOFOM'
            });
    }
};