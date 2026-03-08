const Joi = require('joi');
const authValidator = require('../../validators/auth.validator');

describe('Auth Validators', () => {
    describe('register', () => {
        test('should pass for valid data', () => {
            const { error } = authValidator.register.validate({
                name: 'Nguyễn Văn A',
                phone: '0901234567',
                password: '123456',
            });
            expect(error).toBeUndefined();
        });

        test('should fail for short name', () => {
            const { error } = authValidator.register.validate({
                name: 'A',
                phone: '0901234567',
                password: '123456',
            });
            expect(error).toBeDefined();
            expect(error.details[0].message).toContain('2 ký tự');
        });

        test('should fail for invalid phone', () => {
            const { error } = authValidator.register.validate({
                name: 'Test',
                phone: '123',
                password: '123456',
            });
            expect(error).toBeDefined();
        });

        test('should fail for missing password', () => {
            const { error } = authValidator.register.validate({
                name: 'Test',
                phone: '0901234567',
            });
            expect(error).toBeDefined();
        });

        test('should fail for short password', () => {
            const { error } = authValidator.register.validate({
                name: 'Test User',
                phone: '0901234567',
                password: '123',
            });
            expect(error).toBeDefined();
            expect(error.details[0].message).toContain('6 ký tự');
        });
    });

    describe('login', () => {
        test('should pass for valid login', () => {
            const { error } = authValidator.login.validate({
                phone: '0901234567',
                password: '123456',
            });
            expect(error).toBeUndefined();
        });

        test('should fail for missing phone', () => {
            const { error } = authValidator.login.validate({ password: '123456' });
            expect(error).toBeDefined();
        });
    });

    describe('changePassword', () => {
        test('should pass for valid change', () => {
            const { error } = authValidator.changePassword.validate({
                old_password: 'old123',
                new_password: 'new123',
            });
            expect(error).toBeUndefined();
        });

        test('should fail for short new password', () => {
            const { error } = authValidator.changePassword.validate({
                old_password: 'old123',
                new_password: '123',
            });
            expect(error).toBeDefined();
        });
    });

    describe('forgotPassword', () => {
        test('should pass for valid phone', () => {
            const { error } = authValidator.forgotPassword.validate({ phone: '0901234567' });
            expect(error).toBeUndefined();
        });
    });

    describe('verifyOTP', () => {
        test('should pass for valid OTP', () => {
            const { error } = authValidator.verifyOTP.validate({
                phone: '0901234567',
                otp: '123456',
            });
            expect(error).toBeUndefined();
        });

        test('should fail for OTP length != 6', () => {
            const { error } = authValidator.verifyOTP.validate({
                phone: '0901234567',
                otp: '12345',
            });
            expect(error).toBeDefined();
        });
    });

    describe('resetPassword', () => {
        test('should pass for valid reset', () => {
            const { error } = authValidator.resetPassword.validate({
                reset_token: 'abc123tokenvalue',
                new_password: '123456',
            });
            expect(error).toBeUndefined();
        });
    });
});
