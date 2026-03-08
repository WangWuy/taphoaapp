const Joi = require('joi');

const createOrder = Joi.object({
    address_id: Joi.string().uuid().required()
        .messages({ 'any.required': 'Vui lòng chọn địa chỉ giao hàng' }),
    payment_method: Joi.string().valid('cod', 'bank_transfer').required()
        .messages({ 'any.required': 'Vui lòng chọn phương thức thanh toán' }),
    note: Joi.string().max(500).allow('', null).optional(),
});

module.exports = { createOrder };
