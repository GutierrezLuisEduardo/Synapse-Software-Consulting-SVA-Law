const express  = require('express');
const router   = express.Router();
const opCtrl   = require('../controllers/operacion.controller');
const isAuth   = require('../middleware/is-auth');
const roleAuth = require('../middleware/role-auth');
const ROLES    = require('../config/roles');

router.get('/operaciones/alta', isAuth,
    roleAuth(ROLES.ADMIN, ROLES.OFICIAL, ROLES.EMPLEADO, ROLES.AUDITOR),
    opCtrl.getAltaOperacion);

router.post('/operaciones/alta', isAuth,
    roleAuth(ROLES.EMPLEADO, ROLES.OFICIAL, ROLES.ADMIN),
    opCtrl.postAltaOperacion);

router.get('/operaciones/exportar', isAuth,
    roleAuth(ROLES.ADMIN, ROLES.OFICIAL, ROLES.EMPLEADO, ROLES.AUDITOR),
    opCtrl.exportarHistorial);

router.get('/operaciones', isAuth,
    roleAuth(ROLES.ADMIN, ROLES.OFICIAL, ROLES.EMPLEADO, ROLES.AUDITOR),
    opCtrl.getOperaciones);

router.get('/clientes/:clienteId/contratos', isAuth,
    roleAuth(ROLES.ADMIN, ROLES.OFICIAL, ROLES.EMPLEADO, ROLES.AUDITOR),
    opCtrl.getContratosPorCliente);

router.get('/operaciones/:id', isAuth,
    roleAuth(ROLES.ADMIN, ROLES.OFICIAL, ROLES.EMPLEADO, ROLES.AUDITOR),
    opCtrl.getDetalleOperacion);

module.exports = router;