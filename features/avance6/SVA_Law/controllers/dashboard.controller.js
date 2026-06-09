const ROLES = require('../config/roles');

exports.getDashboard = (req, res) => {
    const usuario = req.session.usuario;
    const esAdmin = usuario.rol === ROLES.ADMIN;

    res.render('dashboard/index', {usuario, esAdmin});
};