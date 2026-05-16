module.exports = (...rolesPermitidos) => {
    return (req, res, next) => {
        const rol = req.session.usuario.rol;
        if (
            !rolesPermitidos.includes(rol)
        ) {
            return res.status(403).render('error/403');
        }
        next();
    };
};