const bcrypt = require('bcryptjs');
const { Op } = require('sequelize');
const { User, RefreshToken, PasswordReset } = require('../models');
const AppError = require('../utils/AppError');
const logger = require('../utils/logger');
const { generateAccessToken } = require('../middleware/auth');

const register = async ({ name, phone, email, password }) => {
    const existingPhone = await User.scope('withPassword').findOne({ where: { phone } });
    if (existingPhone) throw new AppError('Số điện thoại đã được sử dụng', 400);

    if (email) {
        const existingEmail = await User.scope('withPassword').findOne({ where: { email } });
        if (existingEmail) throw new AppError('Email đã được sử dụng', 400);
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const user = await User.create({
        name, phone,
        email: email || null,
        password_hash: passwordHash,
        role: 'customer',
    });

    const accessToken = generateAccessToken(user.id);
    const refreshTokenRecord = await RefreshToken.createForUser(user.id);
    const userData = await User.findByPk(user.id);

    return {
        user: userData,
        token: accessToken,
        refreshToken: refreshTokenRecord.token,
    };
};

const login = async ({ phone, password }) => {
    const user = await User.scope('withPassword').findOne({ where: { phone } });
    if (!user) throw new AppError('Số điện thoại hoặc mật khẩu không đúng', 401);
    if (!user.is_active) throw new AppError('Tài khoản đã bị khóa', 401);

    const isValid = await bcrypt.compare(password, user.password_hash);
    if (!isValid) throw new AppError('Số điện thoại hoặc mật khẩu không đúng', 401);

    const accessToken = generateAccessToken(user.id);
    const refreshTokenRecord = await RefreshToken.createForUser(user.id);
    const userData = await User.findByPk(user.id);

    return {
        user: userData,
        token: accessToken,
        refreshToken: refreshTokenRecord.token,
    };
};

const refreshAccessToken = async (refreshToken) => {
    if (!refreshToken) throw new AppError('Refresh token là bắt buộc', 400);

    const tokenRecord = await RefreshToken.findOne({
        where: { token: refreshToken, revoked_at: null },
    });

    if (!tokenRecord) throw new AppError('Refresh token không hợp lệ', 401);
    if (new Date() > tokenRecord.expires_at) {
        await tokenRecord.update({ revoked_at: new Date() });
        throw new AppError('Refresh token đã hết hạn', 401);
    }

    const user = await User.findByPk(tokenRecord.user_id);
    if (!user || !user.is_active) throw new AppError('Tài khoản không tồn tại hoặc đã bị khóa', 401);

    const accessToken = generateAccessToken(user.id);

    return { token: accessToken, user };
};

const logout = async (refreshToken) => {
    if (!refreshToken) return;
    await RefreshToken.update(
        { revoked_at: new Date() },
        { where: { token: refreshToken, revoked_at: null } }
    );
};

const logoutAll = async (userId) => {
    await RefreshToken.update(
        { revoked_at: new Date() },
        { where: { user_id: userId, revoked_at: null } }
    );
};

const updateProfile = async (userId, { name, email }) => {
    const user = await User.findByPk(userId);
    const updates = {};

    if (name !== undefined) updates.name = name;
    if (email !== undefined) {
        if (email) {
            const existing = await User.findOne({ where: { email } });
            if (existing && existing.id !== userId) {
                throw new AppError('Email đã được sử dụng', 400);
            }
        }
        updates.email = email || null;
    }

    await user.update(updates);
    return User.findByPk(userId);
};

const changePassword = async (userId, { old_password, new_password }) => {
    const user = await User.scope('withPassword').findByPk(userId);
    const isValid = await bcrypt.compare(old_password, user.password_hash);
    if (!isValid) throw new AppError('Mật khẩu cũ không đúng', 400);

    const newHash = await bcrypt.hash(new_password, 10);
    await user.update({ password_hash: newHash });

    // Revoke all refresh tokens on password change
    await logoutAll(userId);
};

// ─── Forgot Password Flow ─────────────────────────────────
const forgotPassword = async ({ phone }) => {
    const user = await User.findOne({ where: { phone } });
    if (!user) throw new AppError('Số điện thoại không tồn tại trong hệ thống', 404);

    // Invalidate previous unused OTPs
    await PasswordReset.update(
        { used_at: new Date() },
        { where: { user_id: user.id, used_at: null } }
    );

    const otp = PasswordReset.generateOTP();
    const expiresAt = new Date();
    expiresAt.setMinutes(expiresAt.getMinutes() + 5);

    await PasswordReset.create({
        user_id: user.id,
        otp,
        expires_at: expiresAt,
    });

    // In dev: log OTP. In production: send via SMS API
    if (process.env.NODE_ENV !== 'production') {
        logger.info(`🔑 OTP for ${phone}: ${otp}`);
    } else {
        // TODO: Integrate SMS API (Twilio, SpeedSMS, etc.)
        logger.info(`📱 OTP sent to ${phone}`);
    }

    return { message: 'Mã OTP đã được gửi đến số điện thoại của bạn' };
};

const verifyOTP = async ({ phone, otp }) => {
    const user = await User.findOne({ where: { phone } });
    if (!user) throw new AppError('Số điện thoại không tồn tại', 404);

    const resetRecord = await PasswordReset.findOne({
        where: {
            user_id: user.id,
            used_at: null,
            expires_at: { [Op.gt]: new Date() },
        },
        order: [['created_at', 'DESC']],
    });

    if (!resetRecord) throw new AppError('Mã OTP đã hết hạn hoặc không tồn tại', 400);

    // Check max attempts (5)
    if (resetRecord.attempts >= 5) {
        await resetRecord.update({ used_at: new Date() });
        throw new AppError('Đã vượt quá số lần thử. Vui lòng yêu cầu mã OTP mới', 400);
    }

    if (resetRecord.otp !== otp) {
        await resetRecord.increment('attempts');
        throw new AppError(`Mã OTP không đúng. Còn ${4 - resetRecord.attempts} lần thử`, 400);
    }

    // OTP correct — generate reset token
    const resetToken = PasswordReset.generateResetToken();
    await resetRecord.update({ reset_token: resetToken });

    return { resetToken };
};

const resetPassword = async ({ reset_token, new_password }) => {
    if (!reset_token) throw new AppError('Reset token là bắt buộc', 400);

    const resetRecord = await PasswordReset.findOne({
        where: {
            reset_token,
            used_at: null,
            expires_at: { [Op.gt]: new Date() },
        },
    });

    if (!resetRecord) throw new AppError('Reset token không hợp lệ hoặc đã hết hạn', 400);

    const newHash = await bcrypt.hash(new_password, 10);
    await User.update({ password_hash: newHash }, { where: { id: resetRecord.user_id } });

    // Mark as used
    await resetRecord.update({ used_at: new Date() });

    // Revoke all refresh tokens
    await logoutAll(resetRecord.user_id);

    return { message: 'Đặt lại mật khẩu thành công' };
};

module.exports = {
    register, login, refreshAccessToken, logout, logoutAll,
    updateProfile, changePassword,
    forgotPassword, verifyOTP, resetPassword,
};
