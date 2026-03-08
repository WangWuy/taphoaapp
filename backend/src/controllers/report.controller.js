const catchAsync = require('../utils/catchAsync');
const reportService = require('../services/report.service');

exports.getRevenue = catchAsync(async (req, res) => {
    const result = await reportService.getRevenue(req.query);
    res.json({ status: 'success', ...result });
});

exports.getTopProducts = catchAsync(async (req, res) => {
    const data = await reportService.getTopProducts(req.query);
    res.json({ status: 'success', data });
});

exports.getTopCustomers = catchAsync(async (req, res) => {
    const data = await reportService.getTopCustomers(req.query);
    res.json({ status: 'success', data });
});

exports.getOrderStats = catchAsync(async (req, res) => {
    const result = await reportService.getOrderStats(req.query);
    res.json({ status: 'success', ...result });
});

exports.getInventoryAlerts = catchAsync(async (req, res) => {
    const result = await reportService.getInventoryAlerts(req.query);
    res.json({ status: 'success', ...result });
});
