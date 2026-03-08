const { DataTypes } = require('sequelize');

// Order status constants - exported for reuse across the app
const ORDER_STATUS = {
    PENDING: 'pending',
    CONFIRMED: 'confirmed',
    PREPARING: 'preparing',
    SHIPPING: 'shipping',
    DELIVERED: 'delivered',
    FAILED_DELIVERY: 'failed_delivery',
    CANCELLED: 'cancelled',
};

const PAYMENT_METHOD = {
    COD: 'cod',
    BANK_TRANSFER: 'bank_transfer',
};

const PAYMENT_STATUS = {
    PENDING: 'pending',
    PAID: 'paid',
    FAILED: 'failed',
};

// Valid status transitions (state machine)
const STATUS_TRANSITIONS = {
    [ORDER_STATUS.PENDING]: [ORDER_STATUS.CONFIRMED, ORDER_STATUS.CANCELLED],
    [ORDER_STATUS.CONFIRMED]: [ORDER_STATUS.SHIPPING, ORDER_STATUS.CANCELLED],
    [ORDER_STATUS.PREPARING]: [ORDER_STATUS.SHIPPING],  // backward compat for existing orders
    [ORDER_STATUS.SHIPPING]: [ORDER_STATUS.DELIVERED, ORDER_STATUS.FAILED_DELIVERY],
    [ORDER_STATUS.FAILED_DELIVERY]: [ORDER_STATUS.SHIPPING, ORDER_STATUS.CANCELLED],
    [ORDER_STATUS.DELIVERED]: [],    // Terminal state
    [ORDER_STATUS.CANCELLED]: [],    // Terminal state
};

module.exports = (sequelize) => {
    const Order = sequelize.define('Order', {
        id: {
            type: DataTypes.UUID,
            defaultValue: DataTypes.UUIDV4,
            primaryKey: true,
        },
        order_number: {
            type: DataTypes.STRING(20),
            allowNull: false,
            unique: true,
        },
        user_id: {
            type: DataTypes.UUID,
            allowNull: false,
            references: {
                model: 'users',
                key: 'id',
            },
        },
        address_id: {
            type: DataTypes.UUID,
            allowNull: true,
            references: {
                model: 'addresses',
                key: 'id',
            },
        },
        status: {
            type: DataTypes.ENUM(...Object.values(ORDER_STATUS)),
            allowNull: false,
            defaultValue: ORDER_STATUS.PENDING,
        },
        payment_method: {
            type: DataTypes.ENUM(...Object.values(PAYMENT_METHOD)),
            allowNull: false,
        },
        payment_status: {
            type: DataTypes.ENUM(...Object.values(PAYMENT_STATUS)),
            allowNull: false,
            defaultValue: PAYMENT_STATUS.PENDING,
        },
        subtotal: {
            type: DataTypes.INTEGER,
            allowNull: false,
            validate: {
                min: { args: [0], msg: 'Tổng tiền hàng không hợp lệ' },
            },
        },
        shipping_fee: {
            type: DataTypes.INTEGER,
            allowNull: false,
            defaultValue: 0,
        },
        total: {
            type: DataTypes.INTEGER,
            allowNull: false,
            validate: {
                min: { args: [0], msg: 'Tổng cộng không hợp lệ' },
            },
        },
        note: {
            type: DataTypes.TEXT,
            allowNull: true,
        },
        ordered_at: {
            type: DataTypes.DATE,
            allowNull: false,
            defaultValue: DataTypes.NOW,
        },
        shipped_at: {
            type: DataTypes.DATE,
            allowNull: true,
        },
        delivered_at: {
            type: DataTypes.DATE,
            allowNull: true,
        },
        cancelled_at: {
            type: DataTypes.DATE,
            allowNull: true,
        },
    }, {
        tableName: 'orders',
        timestamps: true,
        underscored: true,
        indexes: [
            { fields: ['user_id'] },
            { fields: ['status'] },
            { fields: ['order_number'] },
            { fields: ['created_at'] },
        ],
    });

    // Instance method: check if status transition is valid
    Order.prototype.canTransitionTo = function (newStatus) {
        const allowedTransitions = STATUS_TRANSITIONS[this.status] || [];
        return allowedTransitions.includes(newStatus);
    };

    // Instance method: transition status with timestamp tracking
    Order.prototype.transitionTo = async function (newStatus, options = {}) {
        if (!this.canTransitionTo(newStatus)) {
            throw new Error(
                `Không thể chuyển trạng thái từ "${this.status}" sang "${newStatus}"`
            );
        }

        const updates = { status: newStatus };

        // Auto-set timestamps based on status
        switch (newStatus) {
            case ORDER_STATUS.SHIPPING:
                updates.shipped_at = new Date();
                break;
            case ORDER_STATUS.DELIVERED:
                updates.delivered_at = new Date();
                if (this.payment_method === PAYMENT_METHOD.COD) {
                    updates.payment_status = PAYMENT_STATUS.PAID;
                }
                break;
            case ORDER_STATUS.CANCELLED:
                updates.cancelled_at = new Date();
                break;
        }

        return this.update(updates, options);
    };

    // Class method: generate unique order number
    Order.generateOrderNumber = async function () {
        const today = new Date();
        const dateStr = today.toISOString().slice(0, 10).replace(/-/g, '');
        const prefix = `TH-${dateStr}`;

        // Find the latest order number for today
        const latestOrder = await Order.findOne({
            where: {
                order_number: {
                    [require('sequelize').Op.like]: `${prefix}-%`,
                },
            },
            order: [['order_number', 'DESC']],
        });

        let sequence = 1;
        if (latestOrder) {
            const lastSeq = parseInt(latestOrder.order_number.split('-').pop(), 10);
            sequence = lastSeq + 1;
        }

        return `${prefix}-${String(sequence).padStart(3, '0')}`;
    };

    Order.associate = (models) => {
        Order.belongsTo(models.User, { foreignKey: 'user_id', as: 'customer' });
        Order.belongsTo(models.Address, { foreignKey: 'address_id', as: 'shippingAddress' });
        Order.hasMany(models.OrderItem, { foreignKey: 'order_id', as: 'items', onDelete: 'CASCADE' });
    };

    // Attach constants to model for external use
    Order.STATUS = ORDER_STATUS;
    Order.PAYMENT_METHOD = PAYMENT_METHOD;
    Order.PAYMENT_STATUS = PAYMENT_STATUS;
    Order.STATUS_TRANSITIONS = STATUS_TRANSITIONS;

    return Order;
};
