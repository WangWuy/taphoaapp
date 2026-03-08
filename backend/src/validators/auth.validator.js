const Joi = require('joi');

const register = Joi.object({
    name: Joi.string().min(2).max(100).required()
        .messages({ 'any.required': 'Vui lòng nhập họ tên', 'string.min': 'Tên phải từ 2 ký tự' }),
    phone: Joi.string().pattern(/^[0-9]{9,11}$/).required()
        .messages({ 'any.required': 'Vui lòng nhập số điện thoại', 'string.pattern.base': 'Số điện thoại không hợp lệ' }),
    email: Joi.string().email().allow('', null).optional()
        .messages({ 'string.email': 'Email không hợp lệ' }),
    password: Joi.string().min(6).required()
        .messages({ 'any.required': 'Vui lòng nhập mật khẩu', 'string.min': 'Mật khẩu phải có ít nhất 6 ký tự' }),
});

const login = Joi.object({
    phone: Joi.string().required()
        .messages({ 'any.required': 'Vui lòng nhập số điện thoại' }),
    password: Joi.string().required()
        .messages({ 'any.required': 'Vui lòng nhập mật khẩu' }),
});

const updateProfile = Joi.object({
    name: Joi.string().min(2).max(100).optional(),
    email: Joi.string().email().allow('', null).optional(),
});

const changePassword = Joi.object({
    old_password: Joi.string().required()
        .messages({ 'any.required': 'Vui lòng nhập mật khẩu cũ' }),
    new_password: Joi.string().min(6).required()
        .messages({ 'any.required': 'Vui lòng nhập mật khẩu mới', 'string.min': 'Mật khẩu mới phải có ít nhất 6 ký tự' }),
});

const refreshToken = Joi.object({
    refreshToken: Joi.string().required()
        .messages({ 'any.required': 'Refresh token là bắt buộc' }),
});

const forgotPassword = Joi.object({
    phone: Joi.string().required()
        .messages({ 'any.required': 'Vui lòng nhập số điện thoại' }),
});

const verifyOTP = Joi.object({
    phone: Joi.string().required()
        .messages({ 'any.required': 'Vui lòng nhập số điện thoại' }),
    otp: Joi.string().length(6).required()
        .messages({ 'any.required': 'Vui lòng nhập mã OTP', 'string.length': 'Mã OTP phải có 6 chữ số' }),
});

const resetPassword = Joi.object({
    reset_token: Joi.string().required()
        .messages({ 'any.required': 'Reset token là bắt buộc' }),
    new_password: Joi.string().min(6).required()
        .messages({ 'any.required': 'Vui lòng nhập mật khẩu mới', 'string.min': 'Mật khẩu mới phải có ít nhất 6 ký tự' }),
});

module.exports = { register, login, updateProfile, changePassword, refreshToken, forgotPassword, verifyOTP, resetPassword };
