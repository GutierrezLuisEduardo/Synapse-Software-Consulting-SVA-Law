const ROLES = require('../config/roles');

module.exports = (req, res, next) => {
    if (req.method === 'POST' && req.session.usuario?.rol === ROLES.AUDITOR) {
        return res.status(403).render('error/403', { usuario: req.session.usuario });
    }
    next();
};