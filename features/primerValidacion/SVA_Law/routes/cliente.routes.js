const express = require('express');
const router = express.Router();
const clienteController = require('../controllers/cliente.controller');
const isAuth = require('../middleware/is-auth');
const roleAuth = require('../middleware/role-auth');
const ROLES = require('../config/roles');

router.get('/clientes', isAuth,
    roleAuth(ROLES.OFICIAL, ROLES.EMPLEADO, ROLES.AUDITOR),
    clienteController.getClientes
);

router.get('/clientes/alta', isAuth,
    roleAuth(ROLES.OFICIAL, ROLES.EMPLEADO, ROLES.AUDITOR),
    clienteController.getAltaCliente
);

router.post('/clientes/alta', isAuth,
    roleAuth(ROLES.EMPLEADO),
    clienteController.postAltaCliente
);

router.get('/clientes/:id', isAuth,
    roleAuth(ROLES.OFICIAL, ROLES.EMPLEADO, ROLES.AUDITOR),
    clienteController.getExpedienteCliente
);

module.exports = router;