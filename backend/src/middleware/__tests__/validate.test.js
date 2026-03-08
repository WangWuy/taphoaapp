const AppError = require('../../utils/AppError');
const validate = require('../validate');
const Joi = require('joi');

describe('validate middleware', () => {
    const schema = Joi.object({
        name: Joi.string().min(2).required(),
        email: Joi.string().email().optional(),
    });

    let res, next;

    beforeEach(() => {
        res = {};
        next = jest.fn();
    });

    test('should call next() for valid body', () => {
        const req = { body: { name: 'Test User', email: 'test@example.com' } };
        validate(schema)(req, res, next);
        expect(next).toHaveBeenCalledWith();
    });

    test('should pass AppError to next for invalid body', () => {
        const req = { body: { name: 'A' } };
        validate(schema)(req, res, next);
        expect(next).toHaveBeenCalledWith(expect.any(AppError));
        expect(next.mock.calls[0][0].statusCode).toBe(400);
    });

    test('should strip unknown fields', () => {
        const req = { body: { name: 'Test User', unknown: 'field' } };
        validate(schema)(req, res, next);
        expect(req.body.unknown).toBeUndefined();
        expect(req.body.name).toBe('Test User');
    });

    test('should validate query source', () => {
        const querySchema = Joi.object({ page: Joi.number().integer().min(1) });
        const req = { query: { page: 'abc' } };
        validate(querySchema, 'query')(req, res, next);
        expect(next).toHaveBeenCalledWith(expect.any(AppError));
    });
});
