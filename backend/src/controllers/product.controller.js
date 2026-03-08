const catchAsync = require('../utils/catchAsync');
const productService = require('../services/product.service');

exports.listProducts = catchAsync(async (req, res) => {
    const result = await productService.listProducts(req.query);
    res.json({ status: 'success', ...result });
});

exports.getProduct = catchAsync(async (req, res) => {
    const product = await productService.getProduct(req.params.id);
    res.json({ status: 'success', data: product });
});

// Admin
exports.adminListProducts = catchAsync(async (req, res) => {
    const products = await productService.adminListProducts(req.query);
    res.json({ status: 'success', data: products });
});

exports.getInventory = catchAsync(async (req, res) => {
    const result = await productService.getInventory(req.query);
    res.json({ status: 'success', ...result });
});

exports.createProduct = catchAsync(async (req, res) => {
    const product = await productService.createProduct(req.body);
    res.status(201).json({ status: 'success', data: product });
});

exports.updateProduct = catchAsync(async (req, res) => {
    const product = await productService.updateProduct(req.params.id, req.body);
    res.json({ status: 'success', data: product });
});

exports.updateStock = catchAsync(async (req, res) => {
    const product = await productService.updateStock(req.params.id, req.body);
    res.json({ status: 'success', data: product });
});

exports.deleteProduct = catchAsync(async (req, res) => {
    await productService.deleteProduct(req.params.id);
    res.json({ status: 'success', message: 'Đã ẩn sản phẩm' });
});

exports.toggleActive = catchAsync(async (req, res) => {
    const product = await productService.toggleActive(req.params.id);
    res.json({ status: 'success', data: product });
});
