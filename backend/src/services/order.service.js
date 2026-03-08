const { Order, OrderItem, CartItem, Product, Address, User, sequelize } = require('../models');
const { Op } = require('sequelize');
const AppError = require('../utils/AppError');
const { getConfig } = require('./config.service');
const { createAndPush, notifyAdmins } = require('./notification.service');

const createOrder = async (userId, { address_id, payment_method, note }) => {
    const t = await sequelize.transaction();
    try {
        const address = await Address.findOne({
            where: { id: address_id, user_id: userId },
            transaction: t,
        });
        if (!address) {
            await t.rollback();
            throw new AppError('Địa chỉ không hợp lệ', 404);
        }

        const cartItems = await CartItem.findAll({
            where: { user_id: userId },
            include: [{ model: Product, as: 'product' }],
            transaction: t,
        });
        if (cartItems.length === 0) {
            await t.rollback();
            throw new AppError('Giỏ hàng trống', 400);
        }

        let subtotal = 0;
        const orderItemsData = [];

        for (const item of cartItems) {
            if (!item.product || !item.product.is_active) {
                await t.rollback();
                throw new AppError(`Sản phẩm "${item.product?.name || 'Không xác định'}" không còn bán`, 400);
            }
            if (item.quantity > item.product.stock_quantity) {
                await t.rollback();
                throw new AppError(`"${item.product.name}" chỉ còn ${item.product.stock_quantity} trong kho`, 400);
            }

            const itemSubtotal = item.product.price * item.quantity;
            subtotal += itemSubtotal;
            orderItemsData.push({
                product_id: item.product_id,
                product_name: item.product.name,
                product_price: item.product.price,
                quantity: item.quantity,
                subtotal: itemSubtotal,
            });
        }

        // Calculate shipping fee
        const config = await getConfig();
        const shippingRules = config?.shipping?.rules || [];
        let shippingFee = 0;
        const sortedRules = [...shippingRules].sort((a, b) => (a.min_order || 0) - (b.min_order || 0));
        for (const rule of sortedRules) {
            const min = rule.min_order || 0;
            const max = rule.max_order;
            if (subtotal >= min && (max === null || max === undefined || subtotal < max)) {
                shippingFee = rule.fee || 0;
                break;
            }
        }

        const total = subtotal + shippingFee;
        const orderNumber = await Order.generateOrderNumber();

        const order = await Order.create({
            order_number: orderNumber,
            user_id: userId,
            address_id,
            payment_method,
            subtotal,
            shipping_fee: shippingFee,
            total,
            note: note || null,
            status: 'pending',
            payment_status: 'pending',
        }, { transaction: t });

        for (const itemData of orderItemsData) {
            await OrderItem.create({ order_id: order.id, ...itemData }, { transaction: t });
        }

        for (const item of cartItems) {
            await Product.update(
                { stock_quantity: item.product.stock_quantity - item.quantity },
                { where: { id: item.product_id }, transaction: t }
            );
        }

        await CartItem.destroy({ where: { user_id: userId }, transaction: t });
        await t.commit();

        const fullOrder = await Order.findByPk(order.id, {
            include: [
                { model: OrderItem, as: 'items' },
                { model: Address, as: 'shippingAddress' },
            ],
        });

        // Notify admins about new order (fire-and-forget)
        notifyAdmins({
            title: '🛒 Đơn hàng mới',
            message: `Đơn #${orderNumber} - ${new Intl.NumberFormat('vi-VN').format(total)}₫`,
            type: 'new_order',
            referenceType: 'order',
            referenceId: order.id,
        }).catch(() => { });

        return fullOrder;
    } catch (error) {
        if (!error.isOperational) await t.rollback().catch(() => { });
        throw error;
    }
};

const getUserOrders = async (userId, { status }) => {
    const where = { user_id: userId };
    if (status) where.status = status;

    return Order.findAll({
        where,
        include: [
            { model: OrderItem, as: 'items' },
            { model: Address, as: 'shippingAddress' },
        ],
        order: [['created_at', 'DESC']],
    });
};

const getOrderDetail = async (userId, orderId) => {
    const order = await Order.findOne({
        where: { id: orderId, user_id: userId },
        include: [
            { model: OrderItem, as: 'items', include: [{ model: Product, as: 'product', attributes: ['id', 'image_url'] }] },
            { model: Address, as: 'shippingAddress' },
        ],
    });
    if (!order) throw new AppError('Đơn hàng không tồn tại', 404);
    return order;
};

const cancelOrder = async (userId, orderId) => {
    const t = await sequelize.transaction();
    try {
        const order = await Order.findOne({
            where: { id: orderId, user_id: userId },
            include: [{ model: OrderItem, as: 'items' }],
            transaction: t,
        });
        if (!order) { await t.rollback(); throw new AppError('Đơn hàng không tồn tại', 404); }
        if (!order.canTransitionTo('cancelled')) {
            await t.rollback();
            throw new AppError('Không thể hủy đơn hàng ở trạng thái hiện tại', 400);
        }

        for (const item of order.items) {
            await Product.increment('stock_quantity', {
                by: item.quantity, where: { id: item.product_id }, transaction: t,
            });
        }

        await order.transitionTo('cancelled', { transaction: t });
        await t.commit();

        // Notify admins about cancellation
        notifyAdmins({
            title: '❌ Khách hủy đơn',
            message: `Đơn #${order.order_number} đã bị khách hủy`,
            type: 'order_cancelled',
            referenceType: 'order',
            referenceId: order.id,
        }).catch(() => { });

        return order;
    } catch (error) {
        if (!error.isOperational) await t.rollback().catch(() => { });
        throw error;
    }
};

const confirmDelivery = async (userId, orderId) => {
    const order = await Order.findOne({ where: { id: orderId, user_id: userId } });
    if (!order) throw new AppError('Đơn hàng không tồn tại', 404);
    if (order.status !== 'shipping') throw new AppError('Chỉ có thể xác nhận khi đơn đang giao', 400);

    await order.transitionTo('delivered');

    // Notify admins about delivery confirmation
    notifyAdmins({
        title: '✅ Đã giao thành công',
        message: `KH xác nhận nhận đơn #${order.order_number}`,
        type: 'delivery_confirmed',
        referenceType: 'order',
        referenceId: order.id,
    }).catch(() => { });

    return order;
};

const confirmPayment = async (userId, orderId) => {
    const order = await Order.findOne({
        where: { id: orderId, user_id: userId },
    });
    if (!order) throw new AppError('Đơn hàng không tồn tại', 404);
    if (order.payment_method !== 'bank_transfer') throw new AppError('Đơn này không phải chuyển khoản', 400);
    if (order.payment_status === 'paid') throw new AppError('Đã xác nhận thanh toán rồi', 400);

    await order.update({ payment_status: 'paid' });

    // Notify admins
    notifyAdmins({
        title: '💸 Xác nhận chuyển khoản',
        message: `KH đã CK cho đơn #${order.order_number}`,
        type: 'payment_confirmed',
        referenceType: 'order',
        referenceId: order.id,
    }).catch(() => { });

    return order;
};

// Admin methods
const adminGetOrders = async ({ status, search, date_from, date_to, page = 1, limit = 20 }) => {
    const where = {};
    if (status) {
        where.status = status.includes(',') ? { [Op.in]: status.split(',') } : status;
    }
    if (date_from || date_to) {
        where.created_at = {};
        if (date_from) where.created_at[Op.gte] = new Date(date_from);
        if (date_to) where.created_at[Op.lte] = new Date(date_to + 'T23:59:59');
    }

    const customerInclude = { model: User, as: 'customer', attributes: ['id', 'name', 'phone', 'email'] };

    if (search) {
        const matchingUsers = await User.findAll({
            where: { [Op.or]: [{ name: { [Op.iLike]: `%${search}%` } }, { phone: { [Op.iLike]: `%${search}%` } }] },
            attributes: ['id'],
        });
        const matchingUserIds = matchingUsers.map(u => u.id);

        where[Op.or] = [{ order_number: { [Op.iLike]: `%${search}%` } }];
        if (matchingUserIds.length > 0) {
            where[Op.or].push({ user_id: { [Op.in]: matchingUserIds } });
        }
    }

    const offset = (parseInt(page) - 1) * parseInt(limit);
    const { count, rows } = await Order.findAndCountAll({
        where,
        include: [
            customerInclude,
            { model: OrderItem, as: 'items' },
            { model: Address, as: 'shippingAddress' },
        ],
        order: [['created_at', 'DESC']],
        limit: parseInt(limit),
        offset,
        distinct: true,
    });

    return {
        data: rows,
        pagination: {
            total: count,
            page: parseInt(page),
            limit: parseInt(limit),
            totalPages: Math.ceil(count / parseInt(limit)),
        },
    };
};

const adminGetOrderDetail = async (orderId) => {
    const order = await Order.findByPk(orderId, {
        include: [
            { model: User, as: 'customer', attributes: ['id', 'name', 'phone', 'email'] },
            { model: OrderItem, as: 'items', include: [{ model: Product, as: 'product', attributes: ['id', 'image_url', 'name'] }] },
            { model: Address, as: 'shippingAddress' },
        ],
    });
    if (!order) throw new AppError('Đơn hàng không tồn tại', 404);
    return order;
};

const adminUpdateOrderStatus = async (orderId, newStatus) => {
    const t = await sequelize.transaction();
    try {
        const order = await Order.findByPk(orderId, {
            include: [{ model: OrderItem, as: 'items' }],
            transaction: t,
        });
        if (!order) { await t.rollback(); throw new AppError('Đơn hàng không tồn tại', 404); }
        if (!order.canTransitionTo(newStatus)) {
            await t.rollback();
            throw new AppError(`Không thể chuyển từ "${order.status}" sang "${newStatus}"`, 400);
        }

        if (newStatus === 'cancelled') {
            for (const item of order.items) {
                await Product.increment('stock_quantity', {
                    by: item.quantity, where: { id: item.product_id }, transaction: t,
                });
            }
        }

        await order.transitionTo(newStatus, { transaction: t });
        await t.commit();

        const STATUS_LABELS = {
            confirmed: 'đã được xác nhận',
            preparing: 'đang được chuẩn bị',
            shipping: 'đang được giao',
            delivered: 'đã giao thành công',
            cancelled: 'đã bị hủy',
        };

        // Notify customer about status change (fire-and-forget)
        createAndPush(order.user_id, {
            title: '📦 Cập nhật đơn hàng',
            message: `Đơn #${order.order_number} ${STATUS_LABELS[newStatus] || newStatus}`,
            type: 'order_status',
            referenceType: 'order',
            referenceId: order.id,
        }).catch(() => { });

        return Order.findByPk(order.id, {
            include: [
                { model: User, as: 'customer', attributes: ['id', 'name', 'phone', 'email'] },
                { model: OrderItem, as: 'items' },
                { model: Address, as: 'shippingAddress' },
            ],
        });
    } catch (error) {
        if (!error.isOperational) await t.rollback().catch(() => { });
        throw error;
    }
};

const getOrderCounts = async () => {
    const [results] = await sequelize.query(`
        SELECT 
            COUNT(*) FILTER (WHERE status = 'pending') AS pending,
            COUNT(*) FILTER (WHERE status IN ('confirmed', 'preparing', 'shipping')) AS processing,
            COUNT(*) FILTER (WHERE status = 'delivered') AS delivered,
            COUNT(*) FILTER (WHERE status = 'cancelled') AS cancelled
        FROM orders
    `);
    return results[0];
};

const getDashboardStats = async () => {
    const totalOrders = await Order.count();
    const pendingOrders = await Order.count({ where: { status: 'pending' } });
    const totalCustomers = await User.count({ where: { role: 'customer' } });
    const totalProducts = await Product.count();
    const totalRevenue = await Order.sum('total', { where: { status: 'delivered' } }) || 0;
    const lowStockProducts = await Product.count({
        where: { stock_quantity: { [Op.lte]: 10 }, is_active: true },
    });

    return { totalOrders, pendingOrders, totalCustomers, totalProducts, totalRevenue, lowStockProducts };
};

module.exports = {
    createOrder, getUserOrders, getOrderDetail, cancelOrder, confirmDelivery, confirmPayment,
    adminGetOrders, adminGetOrderDetail, adminUpdateOrderStatus,
    getOrderCounts, getDashboardStats,
};
