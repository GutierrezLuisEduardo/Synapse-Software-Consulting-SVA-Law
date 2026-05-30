const express = require('express');
const router = express.Router();
const alertaController = require('../controllers/alerta.controller');
const isAuth = require('../middleware/is-auth');
const roleAuth = require('../middleware/role-auth');
const ROLES = require('../config/roles');

const todosLosRoles = roleAuth(ROLES.ADMIN, ROLES.OFICIAL, ROLES.EMPLEADO, ROLES.AUDITOR);

router.get('/alertas', isAuth, todosLosRoles, alertaController.getAlertas);
router.get('/alertas/:id', isAuth, todosLosRoles, alertaController.getDetalleAlerta);

module.exports = router;