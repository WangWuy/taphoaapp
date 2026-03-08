const catchAsync = require('../utils/catchAsync');
const addressService = require('../services/address.service');

exports.getAddresses = catchAsync(async (req, res) => {
    const addresses = await addressService.getAddresses(req.userId);
    res.json({ status: 'success', data: addresses });
});

exports.createAddress = catchAsync(async (req, res) => {
    const address = await addressService.createAddress(req.userId, req.body);
    res.status(201).json({ status: 'success', data: address });
});

exports.updateAddress = catchAsync(async (req, res) => {
    const address = await addressService.updateAddress(req.userId, req.params.id, req.body);
    res.json({ status: 'success', data: address });
});

exports.deleteAddress = catchAsync(async (req, res) => {
    await addressService.deleteAddress(req.userId, req.params.id);
    res.json({ status: 'success', message: 'Đã xóa địa chỉ' });
});

exports.setDefault = catchAsync(async (req, res) => {
    const address = await addressService.setDefaultAddress(req.userId, req.params.id);
    res.json({ status: 'success', data: address });
});
