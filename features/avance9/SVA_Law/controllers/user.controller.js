const bcrypt = require('bcryptjs');
const Usuario = require('../models/usuario.model');
const Sofom = require('../models/sofom.model');

exports.getCreateUser = async (req, res) => {
    try {
        const rolesResult = await Usuario.fetchRoles();
        const sofomId = req.session.usuario.sofom_id;
        const sofomResult = await Sofom.fetchById(sofomId);

        res.render('users/create', {
            usuario: req.session.usuario,
            activePage: 'admin',
            roles: rolesResult.rows,
            sofom: sofomResult.rows[0] || null,
            error: null,
            valores: null
        });
    } catch (error) {
        console.error(error);
        res.status(500).send('Error interno del servidor');
    }
};

exports.postCreateUser = async (req, res) => {
    try {
        const { nombre, correo_electronico, contrasena, confirmar_contrasena, rol_id } = req.body;

        const sofomId = req.session.usuario.sofom_id;

        const rolesResult = await Usuario.fetchRoles();
        const sofomResult = await Sofom.fetchById(sofomId);
        const roles = rolesResult.rows;
        const sofom = sofomResult.rows[0] || null;

        const renderError = (msg) => res.render('users/create', {
            usuario: req.session.usuario,
            activePage: 'admin',
            roles,
            sofom,
            error: msg,
            valores: { nombre, correo_electronico, rol_id }
        });

        if (!sofom) return renderError('No se encontró la SOFOM asignada a tu cuenta');
        if (contrasena.length < 8) return renderError('La contraseña debe tener mínimo 8 caracteres');
        if (contrasena !== confirmar_contrasena) return renderError('Las contraseñas no coinciden');

        const usuarioExistente = await Usuario.fetchByEmail(correo_electronico);
        if (usuarioExistente.rows.length > 0) return renderError('El correo electrónico ya está registrado');

        const hash = await bcrypt.hash(contrasena, 10);
        await Usuario.create(nombre, correo_electronico, hash, rol_id, sofomId);

        res.redirect('/users/create');
    } catch (error) {
        console.error(error);
        res.status(500).send('Error interno del servidor');
    }
};

exports.getCreateAdminRoot = async (req, res) => {
    try {
        const rolesResult = await Usuario.fetchRolesAdmin();
        const sofomsResult = await Sofom.fetchAll();

        res.render('users/create-admin-root', {
            usuario: req.session.usuario,
            activePage: 'create-admin-root',
            roles: rolesResult.rows,
            sofoms: sofomsResult.rows,
            error: null,
            valores: null
        });
    } catch (error) {
        console.error(error);
        res.status(500).send('Error interno del servidor');
    }
};

exports.postCreateAdminRoot = async (req, res) => {
    try {
        const { nombre, correo_electronico, contrasena, confirmar_contrasena, rol_id, sofom_id } = req.body;

        const rolesResult = await Usuario.fetchRolesAdmin();
        const sofomsResult = await Sofom.fetchAll();
        const roles = rolesResult.rows;
        const sofoms = sofomsResult.rows;

        const renderError = (msg) => res.render('users/create-admin-root', {
            usuario: req.session.usuario,
            activePage: 'create-admin-root',
            roles,
            sofoms,
            error: msg,
            valores: { nombre, correo_electronico, rol_id, sofom_id }
        });

        if (!sofom_id) return renderError('Debes seleccionar una SOFOM');
        if (contrasena.length < 8) return renderError('La contraseña debe tener mínimo 8 caracteres');
        if (contrasena !== confirmar_contrasena) return renderError('Las contraseñas no coinciden');

        const sofomResult = await Sofom.fetchById(sofom_id);
        if (!sofomResult.rows.length) return renderError('La SOFOM seleccionada no existe');

        const rolValido = roles.find(r => r.rol_id == rol_id);
        if (!rolValido) return renderError('Rol no válido para esta operación');

        const usuarioExistente = await Usuario.fetchByEmail(correo_electronico);
        if (usuarioExistente.rows.length > 0) return renderError('El correo electrónico ya está registrado');

        const hash = await bcrypt.hash(contrasena, 10);
        await Usuario.create(nombre, correo_electronico, hash, rol_id, sofom_id);

        res.redirect('/root/users/create-admin');
    } catch (error) {
        console.error(error);
        res.status(500).send('Error interno del servidor');
    }
};