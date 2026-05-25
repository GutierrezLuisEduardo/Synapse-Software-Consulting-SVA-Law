const express = require('express');
const router = express.Router();
const sofomController = require('../controllers/sofom.controller');
const isAuth = require('../middleware/is-auth');
const roleAuth = require('../middleware/role-auth');
const ROLES = require('../config/roles');

router.get('/sofomes', isAuth, roleAuth(ROLES.ADMIN), sofomController.getSofomes);
router.get('/sofomes/:id', isAuth, roleAuth(ROLES.ADMIN), sofomController.getDetalleSofom);

module.exports = router;