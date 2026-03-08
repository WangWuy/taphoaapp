const { DataTypes } = require('sequelize');

const NOTIFICATION_TYPE = {
    NEW_ORDER: 'new_order',
    ORDER_STATUS: 'order_status',
    SYSTEM: 'system',
};

module.exports = (sequelize) => {
    const Notification = sequelize.define('Notification', {
        id: {
            type: DataTypes.UUID,
            defaultValue: DataTypes.UUIDV4,
            primaryKey: true,
        },
        user_id: {
            type: DataTypes.UUID,
            allowNull: false,
            references: {
                model: 'users',
                key: 'id',
            },
        },
        title: {
            type: DataTypes.STRING(200),
            allowNull: false,
        },
        message: {
            type: DataTypes.TEXT,
            allowNull: false,
        },
        type: {
            type: DataTypes.ENUM(...Object.values(NOTIFICATION_TYPE)),
            allowNull: false,
        },
        reference_type: {
            type: DataTypes.STRING(50),
            allowNull: true,
            comment: 'Entity type (e.g., "order", "product")',
        },
        reference_id: {
            type: DataTypes.UUID,
            allowNull: true,
            comment: 'ID of the referenced entity',
        },
        is_read: {
            type: DataTypes.BOOLEAN,
            allowNull: false,
            defaultValue: false,
        },
        read_at: {
            type: DataTypes.DATE,
            allowNull: true,
        },
    }, {
        tableName: 'notifications',
        timestamps: true,
        underscored: true,
        updatedAt: false, // Notifications are immutable except for is_read
        indexes: [
            { fields: ['user_id', 'is_read'] },
            { fields: ['created_at'] },
        ],
        scopes: {
            unread: {
                where: { is_read: false },
                order: [['created_at', 'DESC']],
            },
        },
    });

    // Instance method: mark as read
    Notification.prototype.markAsRead = async function (options = {}) {
        if (this.is_read) return this;
        return this.update(
            { is_read: true, read_at: new Date() },
            options
        );
    };

    Notification.associate = (models) => {
        Notification.belongsTo(models.User, { foreignKey: 'user_id', as: 'user' });
    };

    // Attach constants
    Notification.TYPE = NOTIFICATION_TYPE;

    return Notification;
};
