const AppError = require('../../utils/AppError');
const errorHandler = require('../errorHandler');

describe('errorHandler middleware', () => {
    let req, res, next;

    beforeEach(() => {
        req = { originalUrl: '/api/test', method: 'GET' };
        res = { status: jest.fn().mockReturnThis(), json: jest.fn() };
        next = jest.fn();
    });

    test('should handle operational (AppError) errors', () => {
        const err = new AppError('Not found', 404);
        errorHandler(err, req, res, next);
        expect(res.status).toHaveBeenCalledWith(404);
        expect(res.json).toHaveBeenCalledWith({
            status: 'error',
            message: 'Not found',
        });
    });

    test('should handle SequelizeValidationError', () => {
        const err = new Error('Validation failed');
        err.name = 'SequelizeValidationError';
        err.errors = [{ message: 'field is required' }];
        errorHandler(err, req, res, next);
        expect(res.status).toHaveBeenCalledWith(400);
    });

    test('should handle JWT errors', () => {
        const err = new Error('jwt expired');
        err.name = 'TokenExpiredError';
        errorHandler(err, req, res, next);
        expect(res.status).toHaveBeenCalledWith(401);
        expect(res.json).toHaveBeenCalledWith(
            expect.objectContaining({ message: 'Token đã hết hạn' })
        );
    });

    test('should handle JsonWebTokenError', () => {
        const err = new Error('invalid token');
        err.name = 'JsonWebTokenError';
        errorHandler(err, req, res, next);
        expect(res.status).toHaveBeenCalledWith(401);
    });

    test('should hide details for unknown errors in production', () => {
        const origEnv = process.env.NODE_ENV;
        process.env.NODE_ENV = 'production';

        const err = new Error('DB connection failed');
        errorHandler(err, req, res, next);
        expect(res.status).toHaveBeenCalledWith(500);
        expect(res.json).toHaveBeenCalledWith({
            status: 'error',
            message: 'Đã xảy ra lỗi hệ thống',
        });

        process.env.NODE_ENV = origEnv;
    });
});
