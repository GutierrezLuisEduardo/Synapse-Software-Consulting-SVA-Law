const express   = require('express');
const router    = express.Router();
const multer    = require('multer');
const isAuth    = require('../middleware/is-auth');
const roleAuth  = require('../middleware/role-auth');
const ROLES     = require('../config/roles');
const docCtrl   = require('../controllers/documento.controller');

const upload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 10 * 1024 * 1024 },
    fileFilter: (req, file, cb) => {
        if (file.mimetype === 'application/pdf') {
            cb(null, true);
        } else {
            cb(new Error('Solo se permiten archivos PDF.'));
        }
    }
});

router.get('/documentos/subir', isAuth, roleAuth(ROLES.ADMIN, ROLES.OFICIAL, ROLES.EMPLEADO, ROLES.AUDITOR), docCtrl.getSubirDocumento);

router.post('/documentos/subir', isAuth, roleAuth(ROLES.ADMIN, ROLES.OFICIAL, ROLES.EMPLEADO), upload.single('archivo'), docCtrl.postSubirDocumento);

router.get('/documentos/ver', isAuth, roleAuth(ROLES.ADMIN, ROLES.OFICIAL, ROLES.EMPLEADO, ROLES.AUDITOR), docCtrl.getUrlDocumento);

module.exports = router;