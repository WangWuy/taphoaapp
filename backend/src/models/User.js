const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
    const User = sequelize.define('User', {
        id: {
            type: DataTypes.UUID,
            defaultValue: DataTypes.UUIDV4,
            primaryKey: true,
        },
        name: {
            type: DataTypes.STRING(100),
            allowNull: false,
            validate: {
                notEmpty: { msg: 'Tên không được để trống' },
                len: { args: [2, 100], msg: 'Tên phải từ 2-100 ký tự' },
            },
        },
        email: {
            type: DataTypes.STRING(255),
            allowNull: true,
            unique: {
                msg: 'Email này đã được sử dụng',
            },
            validate: {
                isEmail: { msg: 'Email không hợp lệ' },
            },
        },
        phone: {
            type: DataTypes.STRING(20),
            allowNull: false,
            unique: {
                msg: 'Số điện thoại này đã được sử dụng',
            },
            validate: {
                notEmpty: { msg: 'Số điện thoại không được để trống' },
            },
        },
        password_hash: {
            type: DataTypes.STRING(255),
            allowNull: false,
        },
        role: {
            type: DataTypes.ENUM('customer', 'admin'),
            allowNull: false,
            defaultValue: 'customer',
        },
        avatar_url: {
            type: DataTypes.STRING(500),
            allowNull: true,
        },
        is_active: {
            type: DataTypes.BOOLEAN,
            allowNull: false,
            defaultValue: true,
        },
    }, {
        tableName: 'users',
        timestamps: true,
        underscored: true,
        defaultScope: {
            attributes: { exclude: ['password_hash'] },
        },
        scopes: {
            withPassword: {
                attributes: { include: ['password_hash'] },
            },
            admins: {
                where: { role: 'admin' },
            },
            active: {
                where: { is_active: true },
            },
        },
    });

    User.associate = (models) => {
        User.hasMany(models.Address, { foreignKey: 'user_id', as: 'addresses' });
        User.hasMany(models.CartItem, { foreignKey: 'user_id', as: 'cartItems' });
        User.hasMany(models.Order, { foreignKey: 'user_id', as: 'orders' });
        User.hasMany(models.Notification, { foreignKey: 'user_id', as: 'notifications' });
    };

    return User;
};
