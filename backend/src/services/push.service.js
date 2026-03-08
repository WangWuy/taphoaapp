const admin = require('firebase-admin');
const logger = require('../utils/logger');

let fcmEnabled = false;

// Initialize Firebase Admin if credentials exist
if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    try {
        const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
        admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
        fcmEnabled = true;
        logger.info('🔔 Firebase Cloud Messaging initialized');
    } catch (error) {
        logger.warn('⚠️  Failed to init FCM:', error.message);
    }
} else if (process.env.FIREBASE_PROJECT_ID) {
    try {
        admin.initializeApp({
            credential: admin.credential.cert({
                projectId: process.env.FIREBASE_PROJECT_ID,
                clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
                privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
            }),
        });
        fcmEnabled = true;
        logger.info('🔔 Firebase Cloud Messaging initialized');
    } catch (error) {
        logger.warn('⚠️  Failed to init FCM:', error.message);
    }
} else {
    logger.info('📵 FCM not configured — push notifications disabled');
}

const sendToDevice = async (fcmToken, { title, body, data = {} }) => {
    if (!fcmEnabled) {
        logger.debug(`📵 Push (no FCM): "${title}" → ${fcmToken?.slice(0, 20)}...`);
        return null;
    }

    try {
        const message = {
            notification: { title, body },
            data: Object.fromEntries(
                Object.entries(data).map(([k, v]) => [k, String(v)])
            ),
            token: fcmToken,
        };
        const response = await admin.messaging().send(message);
        logger.debug(`📨 Push sent: ${response}`);
        return response;
    } catch (error) {
        if (error.code === 'messaging/invalid-registration-token' ||
            error.code === 'messaging/registration-token-not-registered') {
            logger.warn(`🗑️ Invalid FCM token, marking inactive: ${fcmToken?.slice(0, 20)}...`);
            const { DeviceToken } = require('../models');
            await DeviceToken.update({ is_active: false }, { where: { fcm_token: fcmToken } });
        } else {
            logger.error(`Push notification error [${error.code || 'UNKNOWN'}]: ${error.message || JSON.stringify(error)}`);
        }
        return null;
    }
};

const sendToUser = async (userId, { title, body, data = {} }) => {
    const { DeviceToken } = require('../models');
    const tokens = await DeviceToken.findAll({
        where: { user_id: userId, is_active: true },
    });

    if (tokens.length === 0) {
        logger.debug(`📵 No active tokens for user ${userId}`);
        return;
    }

    const results = await Promise.allSettled(
        tokens.map(t => sendToDevice(t.fcm_token, { title, body, data }))
    );

    logger.debug(`📨 Push to user ${userId}: ${results.filter(r => r.status === 'fulfilled' && r.value).length}/${tokens.length} sent`);
};

const sendToAdmins = async ({ title, body, data = {} }) => {
    const { User, DeviceToken } = require('../models');
    const admins = await User.findAll({ where: { role: 'admin' }, attributes: ['id'] });
    const adminIds = admins.map(a => a.id);

    if (adminIds.length === 0) return;

    const tokens = await DeviceToken.findAll({
        where: { user_id: adminIds, is_active: true },
    });

    await Promise.allSettled(
        tokens.map(t => sendToDevice(t.fcm_token, { title, body, data }))
    );
};

module.exports = { sendToDevice, sendToUser, sendToAdmins, isFCMEnabled: () => fcmEnabled };
