const express = require('express');
const router = express.Router();
const userController = require('../controllers/user.controller');
const isAuth = require('../middleware/is-auth');
const roleAuth = require('../middleware/role-auth');
const ROLES = require('../config/roles');

router.get('/users/create', isAuth, roleAuth(ROLES.ADMIN), userController.getCreateUser);
router.post('/users/create', isAuth, roleAuth(ROLES.ADMIN), userController.postCreateUser);

router.get('/root/users/create-admin', isAuth, roleAuth(ROLES.ROOT), userController.getCreateAdminRoot);
router.post('/root/users/create-admin', isAuth, roleAuth(ROLES.ROOT), userController.postCreateAdminRoot);

module.exports = router;