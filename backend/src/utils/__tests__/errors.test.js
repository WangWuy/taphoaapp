const AppError = require('../../utils/AppError');
const catchAsync = require('../../utils/catchAsync');

describe('AppError', () => {
    test('should create error with correct statusCode and status', () => {
        const error = new AppError('Not found', 404);
        expect(error.message).toBe('Not found');
        expect(error.statusCode).toBe(404);
        expect(error.status).toBe('fail');
        expect(error.isOperational).toBe(true);
    });

    test('should set status to "error" for 5xx codes', () => {
        const error = new AppError('Server error', 500);
        expect(error.status).toBe('error');
    });

    test('should be instance of Error', () => {
        const error = new AppError('Test', 400);
        expect(error).toBeInstanceOf(Error);
        expect(error).toBeInstanceOf(AppError);
    });
});

describe('catchAsync', () => {
    test('should call next with error when async fn throws', async () => {
        const error = new Error('Async error');
        const fn = catchAsync(async () => { throw error; });
        const next = jest.fn();
        await fn({}, {}, next);
        expect(next).toHaveBeenCalledWith(error);
    });

    test('should not call next when fn succeeds', async () => {
        const fn = catchAsync(async (req, res) => { res.json({ ok: true }); });
        const next = jest.fn();
        const res = { json: jest.fn() };
        await fn({}, res, next);
        expect(next).not.toHaveBeenCalled();
        expect(res.json).toHaveBeenCalledWith({ ok: true });
    });
});
