const express = require('express');
const router = express.Router();
const sofomController = require('../controllers/sofom.controller');
const isAuth = require('../middleware/is-auth');
const roleAuth = require('../middleware/role-auth');
const ROLES = require('../config/roles');

router.get('/sofomes/create', isAuth, roleAuth(ROLES.ROOT), sofomController.getCreateSofom);
router.post('/sofomes/create', isAuth, roleAuth(ROLES.ROOT), sofomController.postCreateSofom);

router.get('/sofomes', isAuth, roleAuth(ROLES.ROOT), sofomController.getSofomes);
router.get('/sofomes/:id', isAuth, roleAuth(ROLES.ROOT), sofomController.getDetalleSofom);

module.exports = router;