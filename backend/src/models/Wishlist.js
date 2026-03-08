const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
    const Wishlist = sequelize.define('Wishlist', {
        id: {
            type: DataTypes.UUID,
            defaultValue: DataTypes.UUIDV4,
            primaryKey: true,
        },
        user_id: {
            type: DataTypes.UUID,
            allowNull: false,
            references: { model: 'users', key: 'id' },
        },
        product_id: {
            type: DataTypes.UUID,
            allowNull: false,
            references: { model: 'products', key: 'id' },
        },
    }, {
        tableName: 'wishlists',
        timestamps: true,
        createdAt: 'created_at',
        updatedAt: false,
        indexes: [
            { unique: true, fields: ['user_id', 'product_id'] },
        ],
    });

    Wishlist.associate = (models) => {
        Wishlist.belongsTo(models.User, { foreignKey: 'user_id' });
        Wishlist.belongsTo(models.Product, { foreignKey: 'product_id', as: 'product' });
    };

    return Wishlist;
};
