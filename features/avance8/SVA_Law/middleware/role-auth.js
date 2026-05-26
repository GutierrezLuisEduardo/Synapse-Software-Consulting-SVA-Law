module.exports = (...rolesPermitidos) => {
    return (req, res, next) => {

        if (!req.session.usuario) {
            return res.redirect('/login');
        }

        const rol = req.session.usuario.rol;

        if (!rolesPermitidos.includes(rol)) {
            return res.status(403).render('error/403');
        }
        
        next();
    };
};