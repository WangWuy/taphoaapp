const catchAsync = require('../utils/catchAsync');
const categoryService = require('../services/category.service');

exports.listActiveCategories = catchAsync(async (req, res) => {
    const categories = await categoryService.listActiveCategories();
    res.json({ status: 'success', data: categories });
});

// Admin
exports.adminListCategories = catchAsync(async (req, res) => {
    const categories = await categoryService.adminListCategories();
    res.json({ status: 'success', data: categories });
});

exports.createCategory = catchAsync(async (req, res) => {
    const category = await categoryService.createCategory(req.body);
    res.status(201).json({ status: 'success', data: category });
});

exports.updateCategory = catchAsync(async (req, res) => {
    const category = await categoryService.updateCategory(req.params.id, req.body);
    res.json({ status: 'success', data: category });
});

exports.deleteCategory = catchAsync(async (req, res) => {
    const result = await categoryService.deleteCategory(req.params.id);
    res.json({ status: 'success', ...result });
});
