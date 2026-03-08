const catchAsync = require('../utils/catchAsync');
const configService = require('../services/config.service');

exports.getConfig = catchAsync(async (req, res) => {
    const config = await configService.getConfig();
    res.json({ status: 'success', data: config });
});

exports.updateConfig = catchAsync(async (req, res) => {
    const config = await configService.updateConfig(req.body);
    res.json({ status: 'success', data: config });
});
