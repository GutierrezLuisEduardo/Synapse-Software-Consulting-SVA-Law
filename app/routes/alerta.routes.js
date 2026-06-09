const express = require('express');
const router = express.Router();
const alertaController = require('../controllers/alerta.controller');
const isAuth = require('../middleware/is-auth');
const roleAuth = require('../middleware/role-auth');
const ROLES = require('../config/roles');
const noAuditor = require('../middleware/no-auditor');

const todosLosRoles = roleAuth(ROLES.ADMIN, ROLES.OFICIAL, ROLES.EMPLEADO, ROLES.AUDITOR);

router.get('/alertas', isAuth, todosLosRoles, alertaController.getAlertas);
router.get('/alertas/exportar/txt',  isAuth, todosLosRoles, alertaController.getExportarAlertas);
router.get('/alertas/descargar-reportes', isAuth, roleAuth(ROLES.OFICIAL, ROLES.ADMIN, ROLES.EMPLEADO), alertaController.getDescargarReportes);
router.get('/alertas/:id', isAuth, todosLosRoles, alertaController.getDetalleAlerta);
router.post('/alertas/:id/dictamen', isAuth, roleAuth(ROLES.OFICIAL, ROLES.ADMIN), alertaController.postDictamen);


module.exports = router;