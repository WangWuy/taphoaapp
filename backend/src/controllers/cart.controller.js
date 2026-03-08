const catchAsync = require('../utils/catchAsync');
const cartService = require('../services/cart.service');

exports.getCart = catchAsync(async (req, res) => {
    const items = await cartService.getCart(req.userId);
    res.json({ status: 'success', data: items });
});

exports.addToCart = catchAsync(async (req, res) => {
    const item = await cartService.addToCart(req.userId, req.body);
    res.status(201).json({ status: 'success', data: item });
});

exports.updateCartItem = catchAsync(async (req, res) => {
    const item = await cartService.updateCartItem(req.userId, req.params.id, req.body);
    if (!item) return res.json({ status: 'success', message: 'Đã xóa khỏi giỏ hàng' });
    res.json({ status: 'success', data: item });
});

exports.deleteCartItem = catchAsync(async (req, res) => {
    await cartService.deleteCartItem(req.userId, req.params.id);
    res.json({ status: 'success', message: 'Đã xóa khỏi giỏ hàng' });
});

exports.clearCart = catchAsync(async (req, res) => {
    await cartService.clearCart(req.userId);
    res.json({ status: 'success', message: 'Đã xóa toàn bộ giỏ hàng' });
});
