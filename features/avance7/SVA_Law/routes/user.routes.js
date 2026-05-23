const express = require('express');
const router = express.Router();
const userController = require('../controllers/user.controller');
const isAuth = require('../middleware/is-auth');
const roleAuth = require('../middleware/role-auth');
const ROLES = require('../config/roles');

router.get('/users/create', isAuth, roleAuth(ROLES.ADMIN), userController.getCreateUser);
router.post('/users/create', isAuth, roleAuth(ROLES.ADMIN), userController.postCreateUser);
router.post('/sofomes/create', isAuth, roleAuth(ROLES.ADMIN), userController.postCreateSofom);

module.exports = router;