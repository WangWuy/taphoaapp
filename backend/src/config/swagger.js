const swaggerJsdoc = require('swagger-jsdoc');

const options = {
    definition: {
        openapi: '3.0.0',
        info: {
            title: 'TạpHóa API',
            version: '1.0.0',
            description: 'API documentation cho TạpHóa - Hệ thống quản lý cửa hàng tạp hóa',
            contact: { name: 'TạpHóa Team' },
        },
        servers: [
            { url: '/api', description: 'API Server' },
        ],
        components: {
            securitySchemes: {
                bearerAuth: {
                    type: 'http',
                    scheme: 'bearer',
                    bearerFormat: 'JWT',
                    description: 'JWT access token',
                },
            },
            schemas: {
                Error: {
                    type: 'object',
                    properties: {
                        status: { type: 'string', example: 'error' },
                        message: { type: 'string' },
                    },
                },
                User: {
                    type: 'object',
                    properties: {
                        id: { type: 'string', format: 'uuid' },
                        name: { type: 'string' },
                        phone: { type: 'string' },
                        email: { type: 'string' },
                        role: { type: 'string', enum: ['customer', 'admin'] },
                    },
                },
                Product: {
                    type: 'object',
                    properties: {
                        id: { type: 'string', format: 'uuid' },
                        name: { type: 'string' },
                        slug: { type: 'string' },
                        price: { type: 'integer' },
                        unit: { type: 'string' },
                        stock_quantity: { type: 'integer' },
                        image_url: { type: 'string', nullable: true },
                        is_active: { type: 'boolean' },
                    },
                },
                Category: {
                    type: 'object',
                    properties: {
                        id: { type: 'integer' },
                        name: { type: 'string' },
                        slug: { type: 'string' },
                        image_url: { type: 'string', nullable: true },
                        is_active: { type: 'boolean' },
                    },
                },
                Order: {
                    type: 'object',
                    properties: {
                        id: { type: 'string', format: 'uuid' },
                        order_number: { type: 'string' },
                        status: { type: 'string', enum: ['pending', 'confirmed', 'preparing', 'shipping', 'delivered', 'cancelled'] },
                        subtotal: { type: 'integer' },
                        shipping_fee: { type: 'integer' },
                        total: { type: 'integer' },
                        payment_method: { type: 'string' },
                    },
                },
            },
        },
        tags: [
            { name: 'Auth', description: 'Authentication & Authorization' },
            { name: 'Products', description: 'Product management' },
            { name: 'Categories', description: 'Category management' },
            { name: 'Cart', description: 'Shopping cart' },
            { name: 'Orders', description: 'Order management' },
            { name: 'Config', description: 'Shop configuration' },
            { name: 'Admin', description: 'Admin operations' },
            { name: 'Reports', description: 'Analytics & Reporting' },
            { name: 'Notifications', description: 'Notifications & Push' },
        ],
    },
    apis: ['./src/docs/*.yaml'],
};

module.exports = swaggerJsdoc(options);
