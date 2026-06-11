const express    = require('express');
const router     = express.Router();
const multer     = require('multer');
const reporteCtrl = require('../controllers/reporte.controller');
const isAuth     = require('../middleware/is-auth');
const roleAuth   = require('../middleware/role-auth');
const noAuditor  = require('../middleware/no-auditor');
const ROLES      = require('../config/roles');

// multer en memoria; solo PDF de hasta 10 MB
const upload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 10 * 1024 * 1024 },
    fileFilter: (_req, file, cb) => {
        if (file.mimetype === 'application/pdf') {
            cb(null, true);
        } else {
            cb(new Error('Solo se permiten archivos PDF.'));
        }
    }
});

router.get(
    '/reportes/crear',
    isAuth,
    roleAuth(ROLES.OFICIAL, ROLES.ADMIN, ROLES.EMPLEADO, ROLES.AUDITOR),
    reporteCtrl.getCrearROIP
);

router.post(
    '/reportes/crear',
    isAuth,
    roleAuth(ROLES.OFICIAL, ROLES.ADMIN, ROLES.EMPLEADO, ROLES.AUDITOR),
    noAuditor,
    upload.single('evidencia'),
    reporteCtrl.postCrearROIP
);

router.get(
    '/reportes/evidencia',
    isAuth,
    roleAuth(ROLES.OFICIAL, ROLES.ADMIN, ROLES.EMPLEADO, ROLES.AUDITOR),
    reporteCtrl.getUrlEvidencia
);

module.exports = router;
