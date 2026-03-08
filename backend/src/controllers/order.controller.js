const catchAsync = require('../utils/catchAsync');
const orderService = require('../services/order.service');

exports.createOrder = catchAsync(async (req, res) => {
    const order = await orderService.createOrder(req.userId, req.body);
    res.status(201).json({ status: 'success', data: order });
});

exports.getUserOrders = catchAsync(async (req, res) => {
    const orders = await orderService.getUserOrders(req.userId, req.query);
    res.json({ status: 'success', data: orders });
});

exports.getOrderDetail = catchAsync(async (req, res) => {
    const order = await orderService.getOrderDetail(req.userId, req.params.id);
    res.json({ status: 'success', data: order });
});

exports.cancelOrder = catchAsync(async (req, res) => {
    const order = await orderService.cancelOrder(req.userId, req.params.id);
    res.json({ status: 'success', data: order });
});

exports.confirmDelivery = catchAsync(async (req, res) => {
    const order = await orderService.confirmDelivery(req.userId, req.params.id);
    res.json({ status: 'success', data: order, message: 'Đã xác nhận nhận hàng' });
});

exports.confirmPayment = catchAsync(async (req, res) => {
    const order = await orderService.confirmPayment(req.userId, req.params.id);
    res.json({ status: 'success', data: order, message: 'Đã xác nhận chuyển khoản' });
});

// Admin
exports.adminGetOrders = catchAsync(async (req, res) => {
    const result = await orderService.adminGetOrders(req.query);
    res.json({ status: 'success', ...result });
});

exports.adminGetOrderDetail = catchAsync(async (req, res) => {
    const order = await orderService.adminGetOrderDetail(req.params.id);
    res.json({ status: 'success', data: order });
});

exports.adminUpdateOrderStatus = catchAsync(async (req, res) => {
    const order = await orderService.adminUpdateOrderStatus(req.params.id, req.body.status);
    res.json({ status: 'success', data: order });
});

exports.getOrderCounts = catchAsync(async (req, res) => {
    const counts = await orderService.getOrderCounts();
    res.json({ status: 'success', data: counts });
});

exports.getDashboardStats = catchAsync(async (req, res) => {
    const stats = await orderService.getDashboardStats();
    res.json({ status: 'success', data: stats });
});
