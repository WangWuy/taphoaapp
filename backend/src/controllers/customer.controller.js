const catchAsync = require('../utils/catchAsync');
const customerService = require('../services/customer.service');

exports.listCustomers = catchAsync(async (req, res) => {
    const customers = await customerService.listCustomers(req.query);
    res.json({ status: 'success', data: customers });
});

exports.getCustomerDetail = catchAsync(async (req, res) => {
    const customer = await customerService.getCustomerDetail(req.params.id);
    res.json({ status: 'success', data: customer });
});
