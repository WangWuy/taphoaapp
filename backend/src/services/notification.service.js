const { Notification, DeviceToken } = require('../models');
const AppError = require('../utils/AppError');
const pushService = require('./push.service');

const getNotifications = async (userId, { page = 1, limit = 20 }) => {
    const offset = (parseInt(page) - 1) * parseInt(limit);

    const { count, rows } = await Notification.findAndCountAll({
        where: { user_id: userId },
        order: [['created_at', 'DESC']],
        limit: parseInt(limit),
        offset,
    });

    const unreadCount = await Notification.count({
        where: { user_id: userId, is_read: false },
    });

    return {
        data: rows,
        pagination: {
            total: count,
            page: parseInt(page),
            limit: parseInt(limit),
            totalPages: Math.ceil(count / parseInt(limit)),
        },
        unreadCount,
    };
};

const markAsRead = async (userId, notificationId) => {
    const notification = await Notification.findOne({
        where: { id: notificationId, user_id: userId },
    });
    if (!notification) throw new AppError('Thông báo không tồn tại', 404);

    await notification.markAsRead();
    return notification;
};

const markAllAsRead = async (userId) => {
    await Notification.update(
        { is_read: true, read_at: new Date() },
        { where: { user_id: userId, is_read: false } }
    );
};

// Create in-app notification + send push
const createAndPush = async (userId, { title, message, type, referenceType, referenceId }) => {
    const notification = await Notification.create({
        user_id: userId,
        title,
        message,
        type: type || 'system',
        reference_type: referenceType || null,
        reference_id: referenceId || null,
    });

    // Send push notification (fire-and-forget)
    pushService.sendToUser(userId, {
        title,
        body: message,
        data: {
            type: type || 'system',
            referenceType: referenceType || '',
            referenceId: referenceId || '',
            notificationId: notification.id,
        },
    }).catch(() => { });

    return notification;
};

// Notify admins (broadcast)
const notifyAdmins = async ({ title, message, type, referenceType, referenceId }) => {
    const { User } = require('../models');
    const admins = await User.findAll({ where: { role: 'admin' }, attributes: ['id'] });

    for (const admin of admins) {
        await createAndPush(admin.id, { title, message, type, referenceType, referenceId });
    }
};

// Device token management
const registerDeviceToken = async (userId, { fcm_token, device_type = 'android' }) => {
    if (!fcm_token) throw new AppError('FCM token là bắt buộc', 400);

    // Upsert: update user_id if token exists, or create new
    const existing = await DeviceToken.findOne({ where: { fcm_token } });
    if (existing) {
        await existing.update({ user_id: userId, device_type, is_active: true });
        return existing;
    }

    return DeviceToken.create({ user_id: userId, fcm_token, device_type });
};

const removeDeviceToken = async (fcmToken) => {
    if (!fcmToken) return;
    await DeviceToken.update({ is_active: false }, { where: { fcm_token: fcmToken } });
};

module.exports = {
    getNotifications, markAsRead, markAllAsRead,
    createAndPush, notifyAdmins,
    registerDeviceToken, removeDeviceToken,
};
