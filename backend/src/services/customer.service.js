const { Op } = require('sequelize');
const { User, Address, Order, OrderItem } = require('../models');
const AppError = require('../utils/AppError');

const listCustomers = async ({ search }) => {
    const where = { role: 'customer' };
    if (search) {
        where[Op.or] = [
            { name: { [Op.iLike]: `%${search}%` } },
            { phone: { [Op.iLike]: `%${search}%` } },
            { email: { [Op.iLike]: `%${search}%` } },
        ];
    }

    const customers = await User.findAll({
        where,
        include: [{ model: Address, as: 'addresses' }],
        order: [['created_at', 'DESC']],
    });

    return Promise.all(customers.map(async (customer) => {
        const orderCount = await Order.count({ where: { user_id: customer.id } });
        return { ...customer.toJSON(), orderCount };
    }));
};

const getCustomerDetail = async (customerId) => {
    const customer = await User.findByPk(customerId, {
        attributes: { exclude: ['password_hash'] },
        include: [{ model: Address, as: 'addresses' }],
    });

    if (!customer || customer.role !== 'customer') {
        throw new AppError('Khách hàng không tồn tại', 404);
    }

    const orders = await Order.findAll({
        where: { user_id: customer.id },
        include: [{ model: OrderItem, as: 'items' }],
        order: [['created_at', 'DESC']],
    });

    const deliveredOrders = orders.filter(o => o.status === 'delivered');
    const stats = {
        totalOrders: orders.length,
        deliveredOrders: deliveredOrders.length,
        cancelledOrders: orders.filter(o => o.status === 'cancelled').length,
        totalSpent: deliveredOrders.reduce((sum, o) => sum + o.total, 0),
    };

    return { ...customer.toJSON(), orders, stats };
};

module.exports = { listCustomers, getCustomerDetail };
