const db = require('../util/database');

module.exports = class Usuario {

    static async fetchByEmail(correoElectronico) {
        const query = `
            SELECT
                u.usuario_id,
                u.nombre,
                u.correo_electronico,
                u.contrasena,
                u.rol_id,
                r.descripcion AS rol,
                u.sofom_id
            FROM usuarios u
            INNER JOIN roles r ON u.rol_id = r.rol_id
            WHERE u.correo_electronico = $1
        `;
        return db.query(query, [correoElectronico]);
    }

    static async fetchRoles() {
        const query = `
            SELECT rol_id, descripcion
            FROM roles
            WHERE descripcion != 'Administrador'
            ORDER BY rol_id ASC
        `;
        return db.query(query);
    }

    static async create(nombre, correoElectronico, contrasena, rolId, sofomId) {
        const query = `
            INSERT INTO usuarios (nombre, correo_electronico, contrasena, rol_id, sofom_id)
            VALUES ($1, $2, $3, $4, $5)
        `;
        return db.query(query, [nombre, correoElectronico, contrasena, rolId, sofomId]);
    }
};