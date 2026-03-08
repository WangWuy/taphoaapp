const catchAsync = require('../utils/catchAsync');
const notificationService = require('../services/notification.service');

exports.getNotifications = catchAsync(async (req, res) => {
    const result = await notificationService.getNotifications(req.userId, req.query);
    res.json({ status: 'success', ...result });
});

exports.markAsRead = catchAsync(async (req, res) => {
    const notification = await notificationService.markAsRead(req.userId, req.params.id);
    res.json({ status: 'success', data: notification });
});

exports.markAllAsRead = catchAsync(async (req, res) => {
    await notificationService.markAllAsRead(req.userId);
    res.json({ status: 'success', message: 'Đã đọc tất cả thông báo' });
});

exports.registerDeviceToken = catchAsync(async (req, res) => {
    const token = await notificationService.registerDeviceToken(req.userId, req.body);
    res.json({ status: 'success', data: token });
});

exports.removeDeviceToken = catchAsync(async (req, res) => {
    await notificationService.removeDeviceToken(req.body.fcm_token);
    res.json({ status: 'success', message: 'Đã xóa device token' });
});
