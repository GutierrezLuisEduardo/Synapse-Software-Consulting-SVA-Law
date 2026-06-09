const express = require('express');
const router = express.Router();
const dashboardController = require('../controllers/dashboard.controller');
const isAuth = require('../middleware/is-auth');

router.get('/dashboard', isAuth, dashboardController.getDashboard);

module.exports = router;