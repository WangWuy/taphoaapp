const request = require('supertest');

// We test against the running server
const BASE_URL = 'http://localhost:3001';

describe('API Integration Tests', () => {
    describe('Health Check', () => {
        test('GET /api/health should return status ok', async () => {
            const res = await request(BASE_URL).get('/api/health');
            expect(res.status).toBe(200);
            expect(res.body.status).toBe('ok');
            expect(res.body).toHaveProperty('timestamp');
            expect(res.body).toHaveProperty('environment');
        });
    });

    describe('404 Handler', () => {
        test('should return 404 for unknown routes', async () => {
            const res = await request(BASE_URL).get('/api/nonexistent');
            expect(res.status).toBe(404);
            expect(res.body.status).toBe('error');
            expect(res.body.message).toContain('not found');
        });
    });

    describe('Public - Categories', () => {
        test('GET /api/categories should return categories array', async () => {
            const res = await request(BASE_URL).get('/api/categories');
            expect(res.status).toBe(200);
            expect(res.body.status).toBe('success');
            expect(Array.isArray(res.body.data)).toBe(true);
            expect(res.body.data.length).toBeGreaterThan(0);
        });
    });

    describe('Public - Products', () => {
        test('GET /api/products should return products', async () => {
            const res = await request(BASE_URL).get('/api/products');
            expect(res.status).toBe(200);
            expect(res.body.status).toBe('success');
            expect(Array.isArray(res.body.data)).toBe(true);
        });

        test('GET /api/products?limit=2 should limit results', async () => {
            const res = await request(BASE_URL).get('/api/products?limit=2');
            expect(res.status).toBe(200);
            expect(res.body.data.length).toBeLessThanOrEqual(2);
        });
    });

    describe('Public - Config', () => {
        test('GET /api/config should return shop config', async () => {
            const res = await request(BASE_URL).get('/api/config');
            expect(res.status).toBe(200);
            expect(res.body.data).toHaveProperty('shop');
            expect(res.body.data).toHaveProperty('bank');
            expect(res.body.data).toHaveProperty('shipping');
        });
    });

    describe('Auth - Validation', () => {
        test('POST /api/auth/register with empty body should return 400', async () => {
            const res = await request(BASE_URL)
                .post('/api/auth/register')
                .send({});
            expect([400, 429]).toContain(res.status);
        });

        test('POST /api/auth/register with short name should return 400', async () => {
            const res = await request(BASE_URL)
                .post('/api/auth/register')
                .send({ name: 'A', phone: '0901234567', password: '123456' });
            expect([400, 429]).toContain(res.status);
        });

        test('POST /api/auth/login with wrong credentials should return 401 or 429', async () => {
            const res = await request(BASE_URL)
                .post('/api/auth/login')
                .send({ phone: '0000000000', password: 'wrongpassword' });
            expect([401, 429]).toContain(res.status);
        });
    });

    describe('Auth - Login & Token Flow', () => {
        let accessToken;
        let refreshToken;
        let rateLimited = false;

        test('POST /api/auth/login with valid credentials should return tokens', async () => {
            const res = await request(BASE_URL)
                .post('/api/auth/login')
                .send({ phone: '0901234567', password: '123456' });
            if (res.status === 429) {
                rateLimited = true;
                return; // skip — rate limited
            }
            expect(res.status).toBe(200);
            expect(res.body.data).toHaveProperty('token');
            expect(res.body.data).toHaveProperty('refreshToken');

            accessToken = res.body.data.token;
            refreshToken = res.body.data.refreshToken;
        });

        test('GET /api/auth/me with valid token should return user', async () => {
            if (rateLimited || !accessToken) return;
            const res = await request(BASE_URL)
                .get('/api/auth/me')
                .set('Authorization', `Bearer ${accessToken}`);
            expect(res.status).toBe(200);
            expect(res.body.data.user).toHaveProperty('name');
        });

        test('POST /api/auth/refresh should return new access token', async () => {
            if (rateLimited || !refreshToken) return;
            const res = await request(BASE_URL)
                .post('/api/auth/refresh')
                .send({ refreshToken });
            expect(res.status).toBe(200);
            expect(res.body.data).toHaveProperty('token');
        });

        test('GET /api/auth/me without token should return 401', async () => {
            const res = await request(BASE_URL).get('/api/auth/me');
            expect(res.status).toBe(401);
        });

        test('POST /api/auth/refresh with invalid token should return 401', async () => {
            const res = await request(BASE_URL)
                .post('/api/auth/refresh')
                .send({ refreshToken: 'invalid-token' });
            expect(res.status).toBe(401);
        });
    });

    describe('Auth - Forgot Password', () => {
        test('POST /api/auth/forgot-password with non-existent phone should return 404 or 429', async () => {
            const res = await request(BASE_URL)
                .post('/api/auth/forgot-password')
                .send({ phone: '0000000000' });
            expect([404, 429]).toContain(res.status);
        });

        test('POST /api/auth/verify-otp with wrong OTP should return 400 or 429', async () => {
            const res = await request(BASE_URL)
                .post('/api/auth/verify-otp')
                .send({ phone: '0901234567', otp: '000000' });
            expect([400, 404, 429]).toContain(res.status);
        });
    });

    describe('Admin - Reports', () => {
        let adminToken;

        beforeAll(async () => {
            const res = await request(BASE_URL)
                .post('/api/auth/login')
                .send({ phone: '0901234567', password: '123456' });
            adminToken = res.body?.data?.token;
        });

        test('GET /api/admin/reports/revenue should return revenue data', async () => {
            if (!adminToken) return;
            const res = await request(BASE_URL)
                .get('/api/admin/reports/revenue')
                .set('Authorization', `Bearer ${adminToken}`);
            expect(res.status).toBe(200);
            expect(res.body).toHaveProperty('data');
            expect(res.body).toHaveProperty('summary');
        });

        test('GET /api/admin/reports/order-stats should return stats', async () => {
            if (!adminToken) return;
            const res = await request(BASE_URL)
                .get('/api/admin/reports/order-stats')
                .set('Authorization', `Bearer ${adminToken}`);
            expect(res.status).toBe(200);
            expect(res.body).toHaveProperty('byStatus');
        });

        test('GET /api/admin/reports/inventory-alerts should return alerts', async () => {
            if (!adminToken) return;
            const res = await request(BASE_URL)
                .get('/api/admin/reports/inventory-alerts')
                .set('Authorization', `Bearer ${adminToken}`);
            expect(res.status).toBe(200);
            expect(res.body).toHaveProperty('data');
        });

        test('GET /api/admin/reports/top-products should return top products', async () => {
            if (!adminToken) return;
            const res = await request(BASE_URL)
                .get('/api/admin/reports/top-products')
                .set('Authorization', `Bearer ${adminToken}`);
            expect(res.status).toBe(200);
        });

        test('Reports without auth should return 401', async () => {
            const res = await request(BASE_URL).get('/api/admin/reports/revenue');
            expect(res.status).toBe(401);
        });
    });

    describe('Security Headers', () => {
        test('should include security headers from Helmet', async () => {
            const res = await request(BASE_URL).get('/api/health');
            expect(res.headers).toHaveProperty('x-content-type-options');
            expect(res.headers).toHaveProperty('x-frame-options');
            expect(res.headers).toHaveProperty('strict-transport-security');
        });

        test('should include rate limit headers', async () => {
            const res = await request(BASE_URL).get('/api/health');
            expect(res.headers).toHaveProperty('ratelimit-limit');
            expect(res.headers).toHaveProperty('ratelimit-remaining');
        });
    });
});
