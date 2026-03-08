require('dotenv').config();

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const { sequelize } = require('./models');
const logger = require('./utils/logger');
const errorHandler = require('./middleware/errorHandler');
const AppError = require('./utils/AppError');
const { globalLimiter } = require('./middleware/rateLimiter');

const app = express();
const PORT = process.env.PORT || 3001;

// ─── Security Middleware ──────────────────────────────────
app.use(helmet());
app.use(cors({
    origin: process.env.CORS_ORIGINS
        ? process.env.CORS_ORIGINS.split(',')
        : '*',
    credentials: true,
}));
app.use(globalLimiter);
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Static files for uploads
app.use('/uploads', express.static('uploads'));

// ─── API Documentation ───────────────────────────────────
if (process.env.NODE_ENV !== 'production') {
    const swaggerUi = require('swagger-ui-express');
    const swaggerSpec = require('./config/swagger');
    app.use('/api/docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec, {
        customCss: '.swagger-ui .topbar { display: none }',
        customSiteTitle: 'TạpHóa API Docs',
    }));
    logger.info('📚 API Docs: http://localhost:' + PORT + '/api/docs');
}

// ─── Health Check ─────────────────────────────────────────
app.get('/api/health', (req, res) => {
    res.json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        environment: process.env.NODE_ENV || 'development',
    });
});

// ─── API Routes ───────────────────────────────────────────
app.use('/api/auth', require('./routes/auth'));
app.use('/api/config', require('./routes/config'));
app.use('/api/categories', require('./routes/categories'));
app.use('/api/products', require('./routes/products'));
app.use('/api/cart', require('./routes/cart'));
app.use('/api/addresses', require('./routes/addresses'));
app.use('/api/orders', require('./routes/orders'));
app.use('/api/notifications', require('./routes/notifications'));
app.use('/api/wishlist', require('./routes/wishlist'));

// Admin routes
app.use('/api/admin/orders', require('./routes/admin/orders'));
app.use('/api/admin/products', require('./routes/admin/products'));
app.use('/api/admin/customers', require('./routes/admin/customers'));
app.use('/api/admin/categories', require('./routes/admin/categories'));
app.use('/api/admin/reports', require('./routes/admin/reports'));

// Upload
app.use('/api/upload', require('./routes/upload'));

// ─── 404 Handler ──────────────────────────────────────────
app.all('*', (req, res, next) => {
    next(new AppError(`Route ${req.method} ${req.url} not found`, 404));
});

// ─── Global Error Handler ─────────────────────────────────
app.use(errorHandler);

// ─── Database Connection & Server Start ───────────────────
const startServer = async () => {
    try {
        await sequelize.authenticate();
        logger.info('✅ Database connection established successfully.');

        // Sync database models
        if (process.env.NODE_ENV === 'production') {
            await sequelize.sync(); // Create tables if not exist (safe for production)
            logger.info('✅ Database models synchronized (production).');
        } else {
            await sequelize.sync({ alter: true });
            logger.info('✅ Database models synchronized (dev - alter mode).');
        }

        // Seed default config if not exists
        const { seedDefaults } = require('./services/config.service');
        await seedDefaults();

        // Seed default users if not exists
        const bcrypt = require('bcryptjs');
        const { User } = require('./models');
        const hash = await bcrypt.hash('123456', 10);
        await User.findOrCreate({ where: { phone: '0901234567' }, defaults: { name: 'Admin', password: hash, role: 'admin' } });
        await User.findOrCreate({ where: { phone: '0987654321' }, defaults: { name: 'Khách hàng', password: hash, role: 'customer' } });
        logger.info('✅ Default users seeded.');

        app.listen(PORT, '0.0.0.0', () => {
            logger.info(`🚀 Server is running on http://localhost:${PORT}`);
            logger.info(`📋 Environment: ${process.env.NODE_ENV || 'development'}`);
            logger.info(`📡 API: http://localhost:${PORT}/api`);
        });
    } catch (error) {
        logger.error('❌ Unable to start server:', error);
        process.exit(1);
    }
};

startServer();

module.exports = app;
