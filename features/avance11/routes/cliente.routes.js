const express = require('express');
const router = express.Router();
const clienteController = require('../controllers/cliente.controller');
const isAuth = require('../middleware/is-auth');
const roleAuth = require('../middleware/role-auth');
const ROLES = require('../config/roles');

router.get('/clientes', isAuth,
    roleAuth(ROLES.ADMIN, ROLES.OFICIAL, ROLES.EMPLEADO, ROLES.AUDITOR),
    clienteController.getClientes
);

router.get('/clientes/alta', isAuth,
    roleAuth(ROLES.ADMIN, ROLES.OFICIAL, ROLES.EMPLEADO, ROLES.AUDITOR),
    clienteController.getAltaCliente
);

router.post('/clientes/alta', isAuth,
    roleAuth(ROLES.EMPLEADO, ROLES.OFICIAL, ROLES.ADMIN),
    clienteController.postAltaCliente
);

router.get('/clientes/buscar', isAuth,
    roleAuth(ROLES.ADMIN, ROLES.OFICIAL, ROLES.EMPLEADO, ROLES.AUDITOR),
    clienteController.buscarClientes
);

router.get('/clientes/:id/verificar', isAuth,
    roleAuth(ROLES.ADMIN, ROLES.OFICIAL, ROLES.EMPLEADO, ROLES.AUDITOR),
    clienteController.verificarCliente
);

router.get('/clientes/:id', isAuth,
    roleAuth(ROLES.ADMIN, ROLES.OFICIAL, ROLES.EMPLEADO, ROLES.AUDITOR),
    clienteController.getExpedienteCliente
);

router.post('/clientes/:id/actualizar-perfil', isAuth,
    roleAuth(ROLES.ADMIN, ROLES.OFICIAL, ROLES.EMPLEADO),
    clienteController.postActualizarPerfilCliente
);

router.post('/clientes/:id/actualizar-contrato', isAuth,
    roleAuth(ROLES.ADMIN, ROLES.OFICIAL, ROLES.EMPLEADO),
    clienteController.postActualizarContrato
);

module.exports = router;