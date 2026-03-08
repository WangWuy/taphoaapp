const catchAsync = require('../utils/catchAsync');
const authService = require('../services/auth.service');

exports.register = catchAsync(async (req, res) => {
    const result = await authService.register(req.body);
    res.status(201).json({ status: 'success', data: result });
});

exports.login = catchAsync(async (req, res) => {
    const result = await authService.login(req.body);
    res.json({ status: 'success', data: result });
});

exports.refresh = catchAsync(async (req, res) => {
    const result = await authService.refreshAccessToken(req.body.refreshToken);
    res.json({ status: 'success', data: result });
});

exports.logout = catchAsync(async (req, res) => {
    await authService.logout(req.body.refreshToken);
    res.json({ status: 'success', message: 'Đăng xuất thành công' });
});

exports.logoutAll = catchAsync(async (req, res) => {
    await authService.logoutAll(req.userId);
    res.json({ status: 'success', message: 'Đã đăng xuất tất cả thiết bị' });
});

exports.getMe = catchAsync(async (req, res) => {
    res.json({ status: 'success', data: { user: req.user } });
});

exports.updateProfile = catchAsync(async (req, res) => {
    const user = await authService.updateProfile(req.userId, req.body);
    res.json({ status: 'success', data: { user } });
});

exports.changePassword = catchAsync(async (req, res) => {
    await authService.changePassword(req.userId, req.body);
    res.json({ status: 'success', message: 'Đổi mật khẩu thành công' });
});

exports.forgotPassword = catchAsync(async (req, res) => {
    const result = await authService.forgotPassword(req.body);
    res.json({ status: 'success', ...result });
});

exports.verifyOTP = catchAsync(async (req, res) => {
    const result = await authService.verifyOTP(req.body);
    res.json({ status: 'success', data: result });
});

exports.resetPassword = catchAsync(async (req, res) => {
    const result = await authService.resetPassword(req.body);
    res.json({ status: 'success', ...result });
});
