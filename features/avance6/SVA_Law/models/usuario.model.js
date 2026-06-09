const db = require('../util/database');

module.exports = class Usuario {
    static async fetchByEmail(correoElectronico) {
        const query = `
            SELECT
                u.usuario_id,
                u.nombre,
                u.correo_electronico,
                u.contrasena,
                r.descripcion AS rol,
                s.razon_social AS sofom
            FROM Usuarios u

            INNER JOIN Roles r
                ON u.rol_id = r.rol_id

            INNER JOIN SOFOM s
                ON u.sofom_id = s.sofom_id

            WHERE u.correo_electronico = $1
        `;

        return db.query(query, [correoElectronico]);
    }

    static async create(nombre,correoElectronico,contrasena,rolId,sofomId) {
        const query = `
            INSERT INTO Usuarios (
                nombre,
                correo_electronico,
                contrasena,
                rol_id,
                sofom_id
            )
            VALUES ($1, $2, $3, $4, $5)
        `;

        return db.query(query, [nombre,correoElectronico,contrasena,rolId,sofomId]);
    }
};