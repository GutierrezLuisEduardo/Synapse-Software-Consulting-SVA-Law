const bcrypt = require('bcryptjs');
const Usuario = require('../models/usuario.model');

exports.getLogin = (req, res) => {
    res.render('auth/login', {
        error: null
    });
};

exports.postLogin = async (req, res) => {
    const correoElectronico = req.body.correo_electronico;
    const contrasena = req.body.contrasena;

    const usuarioDB = await Usuario.fetchByEmail(correoElectronico);
    if (usuarioDB.rows.length === 0) {
        return res.render('auth/login', {
                error: 'Credenciales incorrectas'
            });
    }

    const usuario = usuarioDB.rows[0];
    const coincide = await bcrypt.compare(contrasena, usuario.contrasena);

    if (!coincide) {
        return res.render('auth/login', {
                error: 'Credenciales incorrectas'
            });
    }

    req.session.usuario = {
        usuario_id: usuario.usuario_id,
        nombre: usuario.nombre,
        correo: usuario.correo_electronico,
        rol: usuario.rol,
        sofom: usuario.sofom
    };

    res.redirect('/dashboard');

};

exports.logout = (req, res) => {
    req.session.destroy(() => {
        res.redirect('/login');
    });
};