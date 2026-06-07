const express      = require('express');
const router       = express.Router();
const isAuth       = require('../middleware/is-auth');
const roleAuth     = require('../middleware/role-auth');
const ROLES        = require('../config/roles');
const contratoCtrl = require('../controllers/contrato.controller');

router.get('/contratos/alta', isAuth, roleAuth(ROLES.ADMIN, ROLES.OFICIAL, ROLES.EMPLEADO, ROLES.AUDITOR), contratoCtrl.getAltaContrato);

router.post('/contratos/alta', isAuth, roleAuth(ROLES.ADMIN, ROLES.OFICIAL, ROLES.EMPLEADO), contratoCtrl.postAltaContrato);

module.exports = router;