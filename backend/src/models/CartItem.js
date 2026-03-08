const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
    const CartItem = sequelize.define('CartItem', {
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
        product_id: {
            type: DataTypes.UUID,
            allowNull: false,
            references: {
                model: 'products',
                key: 'id',
            },
        },
        quantity: {
            type: DataTypes.INTEGER,
            allowNull: false,
            defaultValue: 1,
            validate: {
                min: { args: [1], msg: 'Số lượng phải lớn hơn 0' },
            },
        },
    }, {
        tableName: 'cart_items',
        timestamps: true,
        underscored: true,
        indexes: [
            {
                unique: true,
                fields: ['user_id', 'product_id'],
                name: 'cart_items_user_product_unique',
            },
        ],
    });

    CartItem.associate = (models) => {
        CartItem.belongsTo(models.User, { foreignKey: 'user_id', as: 'user' });
        CartItem.belongsTo(models.Product, { foreignKey: 'product_id', as: 'product' });
    };

    return CartItem;
};
