const bcrypt = require('bcryptjs');
const Usuario = require('../models/usuario.model');

exports.getCreateUser = (req, res) => {
    res.render('users/create');
};

exports.postCreateUser = async (req, res) => {
    const nombre = req.body.nombre;
    const correoElectronico = req.body.correo_electronico;
    const contrasena = req.body.contrasena;
    const rolId = req.body.rol_id;
    const sofomId = req.body.sofom_id;

    if (contrasena.length < 8) {
        return res.send('La contraseña debe tener al menos 8 caracteres');
    }

    const hash = await bcrypt.hash(contrasena, 10);
    
    await Usuario.create(nombre, correoElectronico, hash, rolId, sofomId);

    res.redirect('/dashboard');
};