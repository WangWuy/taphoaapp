const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
    const OrderItem = sequelize.define('OrderItem', {
        id: {
            type: DataTypes.UUID,
            defaultValue: DataTypes.UUIDV4,
            primaryKey: true,
        },
        order_id: {
            type: DataTypes.UUID,
            allowNull: false,
            references: {
                model: 'orders',
                key: 'id',
            },
        },
        product_id: {
            type: DataTypes.UUID,
            allowNull: false,
            references: {
                model: 'products',
                key: 'id',
            },
        },
        // Snapshot fields - preserve data at time of purchase
        product_name: {
            type: DataTypes.STRING(200),
            allowNull: false,
            comment: 'Tên sản phẩm tại thời điểm đặt hàng',
        },
        product_price: {
            type: DataTypes.INTEGER,
            allowNull: false,
            comment: 'Giá sản phẩm tại thời điểm đặt hàng',
        },
        quantity: {
            type: DataTypes.INTEGER,
            allowNull: false,
            validate: {
                min: { args: [1], msg: 'Số lượng phải lớn hơn 0' },
            },
        },
        subtotal: {
            type: DataTypes.INTEGER,
            allowNull: false,
            comment: 'product_price * quantity',
        },
    }, {
        tableName: 'order_items',
        timestamps: true,
        underscored: true,
        updatedAt: false, // Order items should not be updated after creation
    });

    OrderItem.associate = (models) => {
        OrderItem.belongsTo(models.Order, { foreignKey: 'order_id', as: 'order' });
        OrderItem.belongsTo(models.Product, { foreignKey: 'product_id', as: 'product' });
    };

    return OrderItem;
};
