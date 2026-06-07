const express    = require('express');
const router     = express.Router();
const isAuth     = require('../middleware/is-auth');
const roleAuth   = require('../middleware/role-auth');
const ROLES      = require('../config/roles');
const ebrCtrl    = require('../controllers/ebr.controller');

const rolesPermitidos = [ROLES.EMPLEADO, ROLES.ADMIN, ROLES.OFICIAL];

router.get(
    '/ebr/parametrizacion',
    isAuth,
    roleAuth(...rolesPermitidos),
    ebrCtrl.getParametrizacion
);

router.post(
    '/ebr/parametrizacion',
    isAuth,
    roleAuth(...rolesPermitidos),
    ebrCtrl.postParametrizacion
);

module.exports = router;
