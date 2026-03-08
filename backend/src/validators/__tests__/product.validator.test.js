const Joi = require('joi');
const productValidator = require('../../validators/product.validator');

describe('Product Validators', () => {
    describe('createProduct', () => {
        test('should pass for valid product', () => {
            const { error } = productValidator.createProduct.validate({
                name: 'Coca Cola',
                price: 10000,
            });
            expect(error).toBeUndefined();
        });

        test('should fail for missing name', () => {
            const { error } = productValidator.createProduct.validate({ price: 10000 });
            expect(error).toBeDefined();
        });

        test('should fail for negative price', () => {
            const { error } = productValidator.createProduct.validate({
                name: 'Test',
                price: -100,
            });
            expect(error).toBeDefined();
        });
    });

    describe('updateStock', () => {
        test('should pass with quantity', () => {
            const { error } = productValidator.updateStock.validate({ quantity: 50 });
            expect(error).toBeUndefined();
        });

        test('should pass with adjustment', () => {
            const { error } = productValidator.updateStock.validate({ adjustment: -10 });
            expect(error).toBeUndefined();
        });

        test('should fail without quantity or adjustment', () => {
            const { error } = productValidator.updateStock.validate({});
            expect(error).toBeDefined();
        });
    });

    describe('createCategory', () => {
        test('should pass with valid name', () => {
            const { error } = productValidator.createCategory.validate({ name: 'Đồ uống' });
            expect(error).toBeUndefined();
        });

        test('should fail for missing name', () => {
            const { error } = productValidator.createCategory.validate({});
            expect(error).toBeDefined();
        });
    });
});
