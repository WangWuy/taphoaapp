const { sequelize } = require('../models');
const { Op, QueryTypes } = require('sequelize');
const AppError = require('../utils/AppError');

const getRevenue = async ({ period = 'daily', from, to }) => {
    let dateFormat;
    switch (period) {
        case 'monthly': dateFormat = 'YYYY-MM'; break;
        case 'weekly': dateFormat = 'IYYY-IW'; break;
        default: dateFormat = 'YYYY-MM-DD';
    }

    const whereClause = ["status = 'delivered'"];
    const replacements = {};

    if (from) {
        whereClause.push('created_at >= :from');
        replacements.from = new Date(from);
    }
    if (to) {
        whereClause.push('created_at <= :to');
        replacements.to = new Date(to + 'T23:59:59');
    }

    const results = await sequelize.query(`
        SELECT 
            TO_CHAR(created_at, '${dateFormat}') AS period,
            COUNT(*) AS order_count,
            SUM(total) AS revenue,
            SUM(subtotal) AS subtotal,
            SUM(shipping_fee) AS shipping_total
        FROM orders
        WHERE ${whereClause.join(' AND ')}
        GROUP BY period
        ORDER BY period ASC
    `, { replacements, type: QueryTypes.SELECT });

    // Summary
    const summary = results.reduce((acc, row) => ({
        totalRevenue: acc.totalRevenue + parseInt(row.revenue || 0),
        totalOrders: acc.totalOrders + parseInt(row.order_count || 0),
        totalShipping: acc.totalShipping + parseInt(row.shipping_total || 0),
    }), { totalRevenue: 0, totalOrders: 0, totalShipping: 0 });

    return { data: results, summary };
};

const getTopProducts = async ({ limit = 10, from, to }) => {
    const whereClause = ["o.status = 'delivered'"];
    const replacements = {};

    if (from) {
        whereClause.push('o.created_at >= :from');
        replacements.from = new Date(from);
    }
    if (to) {
        whereClause.push('o.created_at <= :to');
        replacements.to = new Date(to + 'T23:59:59');
    }

    const results = await sequelize.query(`
        SELECT 
            oi.product_id,
            oi.product_name,
            p.image_url,
            p.price AS current_price,
            SUM(oi.quantity) AS total_sold,
            SUM(oi.subtotal) AS total_revenue,
            COUNT(DISTINCT oi.order_id) AS order_count
        FROM order_items oi
        JOIN orders o ON o.id = oi.order_id
        LEFT JOIN products p ON p.id = oi.product_id
        WHERE ${whereClause.join(' AND ')}
        GROUP BY oi.product_id, oi.product_name, p.image_url, p.price
        ORDER BY total_sold DESC
        LIMIT :limit
    `, { replacements: { ...replacements, limit: parseInt(limit) }, type: QueryTypes.SELECT });

    return results;
};

const getTopCustomers = async ({ limit = 10, from, to }) => {
    const whereClause = ["o.status = 'delivered'"];
    const replacements = {};

    if (from) {
        whereClause.push('o.created_at >= :from');
        replacements.from = new Date(from);
    }
    if (to) {
        whereClause.push('o.created_at <= :to');
        replacements.to = new Date(to + 'T23:59:59');
    }

    const results = await sequelize.query(`
        SELECT 
            u.id AS user_id,
            u.name,
            u.phone,
            COUNT(o.id) AS order_count,
            SUM(o.total) AS total_spent,
            MAX(o.created_at) AS last_order_at
        FROM orders o
        JOIN users u ON u.id = o.user_id
        WHERE ${whereClause.join(' AND ')}
        GROUP BY u.id, u.name, u.phone
        ORDER BY total_spent DESC
        LIMIT :limit
    `, { replacements: { ...replacements, limit: parseInt(limit) }, type: QueryTypes.SELECT });

    return results;
};

const getOrderStats = async ({ from, to }) => {
    const whereClause = ['1=1'];
    const replacements = {};

    if (from) {
        whereClause.push('created_at >= :from');
        replacements.from = new Date(from);
    }
    if (to) {
        whereClause.push('created_at <= :to');
        replacements.to = new Date(to + 'T23:59:59');
    }

    const results = await sequelize.query(`
        SELECT 
            status,
            COUNT(*) AS count,
            COALESCE(SUM(total), 0) AS total_value
        FROM orders
        WHERE ${whereClause.join(' AND ')}
        GROUP BY status
        ORDER BY count DESC
    `, { replacements, type: QueryTypes.SELECT });

    // Daily trend (last 30 days)
    const trend = await sequelize.query(`
        SELECT 
            TO_CHAR(created_at, 'YYYY-MM-DD') AS date,
            COUNT(*) AS orders,
            COALESCE(SUM(total), 0) AS revenue
        FROM orders
        WHERE created_at >= NOW() - INTERVAL '30 days'
        GROUP BY date
        ORDER BY date ASC
    `, { type: QueryTypes.SELECT });

    return { byStatus: results, dailyTrend: trend };
};

const getInventoryAlerts = async ({ threshold = 10 }) => {
    const results = await sequelize.query(`
        SELECT 
            p.id,
            p.name,
            p.image_url,
            p.stock_quantity,
            p.unit,
            p.price,
            c.name AS category_name,
            CASE 
                WHEN p.stock_quantity = 0 THEN 'out_of_stock'
                WHEN p.stock_quantity <= :threshold THEN 'low_stock'
            END AS alert_type
        FROM products p
        LEFT JOIN categories c ON c.id = p.category_id
        WHERE p.is_active = true AND p.stock_quantity <= :threshold
        ORDER BY p.stock_quantity ASC, p.name ASC
    `, { replacements: { threshold: parseInt(threshold) }, type: QueryTypes.SELECT });

    const summary = {
        outOfStock: results.filter(r => r.alert_type === 'out_of_stock').length,
        lowStock: results.filter(r => r.alert_type === 'low_stock').length,
    };

    return { data: results, summary };
};

module.exports = { getRevenue, getTopProducts, getTopCustomers, getOrderStats, getInventoryAlerts };
