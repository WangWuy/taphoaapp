const express = require('express');
const { authenticate } = require('../middleware/auth');
const notificationController = require('../controllers/notification.controller');

const router = express.Router();
router.use(authenticate);

router.get('/', notificationController.getNotifications);
router.patch('/read-all', notificationController.markAllAsRead);
router.patch('/:id/read', notificationController.markAsRead);

// Device token
router.post('/device-token', notificationController.registerDeviceToken);
router.delete('/device-token', notificationController.removeDeviceToken);
router.delete('/device-token/:token', notificationController.removeDeviceToken);

module.exports = router;
