const bcrypt = require('bcryptjs');
const Usuario = require('../models/usuario.model');
const Sofom = require('../models/sofom.model');

exports.getCreateUser = async (req, res) => {
    try {
        const rolesResult = await Usuario.fetchRoles();
        const sofomesResult = await Sofom.fetchAll();

        res.render('users/create', {
            usuario: req.session.usuario,
            activePage: 'admin',
            roles: rolesResult.rows,
            sofomes: sofomesResult.rows,
            error: null
        });
    } catch (error) {
        console.error(error);
        res.status(500).send('Error interno del servidor');
    }
};

exports.postCreateUser = async (req, res) => {
    try {
        const { nombre, correo_electronico, contrasena, confirmar_contrasena, rol_id, sofom_id } = req.body;

        const rolesResult = await Usuario.fetchRoles();
        const sofomesResult = await Sofom.fetchAll();
        const roles = rolesResult.rows;
        const sofomes = sofomesResult.rows;

        const renderError = (msg) => res.render('users/create', {
            usuario: req.session.usuario,
            activePage: 'admin',
            roles,
            sofomes,
            error: msg
        });

        if (sofomes.length === 0) return renderError('Primero debes registrar una SOFOM');
        if (contrasena.length < 8) return renderError('La contraseña debe tener mínimo 8 caracteres');
        if (contrasena !== confirmar_contrasena) return renderError('Las contraseñas no coinciden');

        const usuarioExistente = await Usuario.fetchByEmail(correo_electronico);
        if (usuarioExistente.rows.length > 0) return renderError('El correo electrónico ya está registrado');

        const hash = await bcrypt.hash(contrasena, 10);
        await Usuario.create(nombre, correo_electronico, hash, rol_id, sofom_id);

        res.redirect('/users/create');
    } catch (error) {
        console.error(error);
        res.status(500).send('Error interno del servidor');
    }
};

exports.postCreateSofom = async (req, res) => {
    try {
        const { razon_social, tipo_entidad_id } = req.body;

        const razonSocialExistente = await Sofom.fetchByRazonSocial(razon_social);
        const rolesResult = await Usuario.fetchRoles();
        const sofomesResult = await Sofom.fetchAll();

        if (razonSocialExistente.rows.length > 0) {
            return res.render('users/create', {
                usuario: req.session.usuario,
                activePage: 'admin',
                roles: rolesResult.rows,
                sofomes: sofomesResult.rows,
                error: 'La razón social ya existe'
            });
        }

        await Sofom.create(razon_social, tipo_entidad_id);
        res.redirect('/users/create');
    } catch (error) {
        console.error(error);
        res.status(500).send('Error interno del servidor');
    }
};