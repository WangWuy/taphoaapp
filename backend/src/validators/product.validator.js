const Joi = require('joi');

const createProduct = Joi.object({
    name: Joi.string().min(1).max(200).required()
        .messages({ 'any.required': 'Tên sản phẩm là bắt buộc' }),
    description: Joi.string().max(5000).allow('', null).optional(),
    price: Joi.number().integer().min(0).required()
        .messages({ 'any.required': 'Giá sản phẩm là bắt buộc' }),
    compare_at_price: Joi.number().integer().min(0).allow(null).optional(),
    cost_price: Joi.number().integer().min(0).allow(null).optional(),
    unit: Joi.string().max(30).optional(),
    stock_quantity: Joi.number().integer().min(0).optional(),
    category_id: Joi.number().integer().allow(null).optional(),
    image_url: Joi.string().uri({ allowRelative: true }).max(500).allow('', null).optional(),
    is_active: Joi.boolean().optional(),
});

const updateProduct = Joi.object({
    name: Joi.string().min(1).max(200).optional(),
    description: Joi.string().max(5000).allow('', null).optional(),
    price: Joi.number().integer().min(0).optional(),
    compare_at_price: Joi.number().integer().min(0).allow(null).optional(),
    cost_price: Joi.number().integer().min(0).allow(null).optional(),
    unit: Joi.string().max(30).optional(),
    stock_quantity: Joi.number().integer().min(0).optional(),
    category_id: Joi.number().integer().allow(null).optional(),
    image_url: Joi.string().uri({ allowRelative: true }).max(500).allow('', null).optional(),
    is_active: Joi.boolean().optional(),
});

const updateStock = Joi.object({
    quantity: Joi.number().integer().min(0).optional(),
    adjustment: Joi.number().integer().optional(),
}).or('quantity', 'adjustment')
    .messages({ 'object.missing': 'Vui lòng cung cấp quantity hoặc adjustment' });

const createCategory = Joi.object({
    name: Joi.string().min(1).max(100).required()
        .messages({ 'any.required': 'Tên danh mục là bắt buộc' }),
    image_url: Joi.string().uri({ allowRelative: true }).max(500).allow('', null).optional(),
    is_active: Joi.boolean().optional(),
    sort_order: Joi.number().integer().min(0).optional(),
});

const updateCategory = Joi.object({
    name: Joi.string().min(1).max(100).optional(),
    image_url: Joi.string().uri({ allowRelative: true }).max(500).allow('', null).optional(),
    is_active: Joi.boolean().optional(),
    sort_order: Joi.number().integer().min(0).optional(),
});

module.exports = { createProduct, updateProduct, updateStock, createCategory, updateCategory };
