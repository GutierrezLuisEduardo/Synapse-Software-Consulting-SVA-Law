const db = require('../util/database');

module.exports = class Sofom {

    static async fetchAll() {
        const query = `
            SELECT
                s.sofom_id,
                s.razon_social,
                s.tipo_entidad_id,
                te.descripcion AS tipo_entidad,
                s.estatus,
                s.fecha_creacion,
                s.canal_privado,
                COUNT(u.usuario_id) AS total_usuarios
            FROM sofom s
            LEFT JOIN tf_tipos_entidad te ON s.tipo_entidad_id = te.tipo_entidad_id
            LEFT JOIN usuarios u ON u.sofom_id = s.sofom_id
            GROUP BY s.sofom_id, s.razon_social, s.tipo_entidad_id, te.descripcion,
                     s.estatus, s.fecha_creacion, s.canal_privado
            ORDER BY s.razon_social ASC
        `;
        return db.query(query);
    }

    static async fetchById(sofomId) {
        const query = `
            SELECT
                s.sofom_id,
                s.razon_social,
                s.tipo_entidad_id,
                te.descripcion AS tipo_entidad,
                s.estatus,
                s.fecha_creacion,
                s.canal_privado
            FROM sofom s
            LEFT JOIN tf_tipos_entidad te ON s.tipo_entidad_id = te.tipo_entidad_id
            WHERE s.sofom_id = $1
        `;
        return db.query(query, [sofomId]);
    }

    static async fetchByIdWithUsuarios(sofomId) {
        const sofomQuery = `
            SELECT
                s.sofom_id,
                s.razon_social,
                s.tipo_entidad_id,
                te.descripcion AS tipo_entidad,
                s.estatus,
                s.fecha_creacion,
                s.canal_privado
            FROM sofom s
            LEFT JOIN tf_tipos_entidad te ON s.tipo_entidad_id = te.tipo_entidad_id
            WHERE s.sofom_id = $1
        `;
        const usuariosQuery = `
            SELECT
                u.usuario_id,
                u.nombre,
                u.correo_electronico,
                r.descripcion AS rol,
                u.estatus,
                u.fecha_creacion
            FROM usuarios u
            INNER JOIN roles r ON u.rol_id = r.rol_id
            WHERE u.sofom_id = $1
            ORDER BY u.nombre ASC
        `;
        const [sofom, usuarios] = await Promise.all([
            db.query(sofomQuery, [sofomId]),
            db.query(usuariosQuery, [sofomId])
        ]);
        return { sofom, usuarios };
    }

    static async fetchByRazonSocial(razonSocial) {
        const query = `
            SELECT sofom_id
            FROM sofom
            WHERE LOWER(razon_social) = LOWER($1)
        `;
        return db.query(query, [razonSocial]);
    }

    static async create(razonSocial, tipoEntidad) {
        const query = `
            INSERT INTO sofom (razon_social, tipo_entidad_id)
            VALUES ($1, $2)
        `;
        return db.query(query, [razonSocial, tipoEntidad]);
    }

    static async fetchTiposEntidad() {
        return db.query(
            'SELECT tipo_entidad_id, descripcion FROM tf_tipos_entidad ORDER BY tipo_entidad_id ASC'
        );
    }
};