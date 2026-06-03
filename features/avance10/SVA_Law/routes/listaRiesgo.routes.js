const express = require('express');
const router = express.Router();
const multer = require('multer');
const isAuth = require('../middleware/is-auth');
const roleAuth = require('../middleware/role-auth');
const ROLES = require('../config/roles');
const listaCtrl = require('../controllers/listaRiesgo.controller');

const upload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 5 * 1024 * 1024 },
    fileFilter: (req, file, cb) => {
        const esTexto = file.mimetype === 'text/plain'
            || file.originalname.toLowerCase().endsWith('.txt');
        esTexto ? cb(null, true) : cb(new Error('Solo se permiten archivos .txt.'));
    }
});

router.get('/listas-bloqueo', isAuth, roleAuth(ROLES.ADMIN, ROLES.OFICIAL, ROLES.EMPLEADO), listaCtrl.getListasBloqueo);

router.post('/listas-bloqueo', isAuth, roleAuth(ROLES.ADMIN, ROLES.OFICIAL, ROLES.EMPLEADO), upload.single('archivo'), listaCtrl.postListasBloqueo);

module.exports = router;