const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
    const Address = sequelize.define('Address', {
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
        recipient_name: {
            type: DataTypes.STRING(100),
            allowNull: false,
            validate: {
                notEmpty: { msg: 'Tên người nhận không được để trống' },
            },
        },
        phone: {
            type: DataTypes.STRING(20),
            allowNull: false,
            validate: {
                notEmpty: { msg: 'Số điện thoại người nhận không được để trống' },
            },
        },
        address_line: {
            type: DataTypes.TEXT,
            allowNull: false,
            validate: {
                notEmpty: { msg: 'Địa chỉ không được để trống' },
            },
        },
        ward: {
            type: DataTypes.STRING(100),
            allowNull: true,
            comment: 'Phường/Xã',
        },
        district: {
            type: DataTypes.STRING(100),
            allowNull: true,
            comment: 'Quận/Huyện',
        },
        city: {
            type: DataTypes.STRING(100),
            allowNull: false,
            validate: {
                notEmpty: { msg: 'Tỉnh/Thành phố không được để trống' },
            },
            comment: 'Tỉnh/Thành phố',
        },
        is_default: {
            type: DataTypes.BOOLEAN,
            allowNull: false,
            defaultValue: false,
        },
    }, {
        tableName: 'addresses',
        timestamps: true,
        underscored: true,
    });

    Address.associate = (models) => {
        Address.belongsTo(models.User, { foreignKey: 'user_id', as: 'user' });
        Address.hasMany(models.Order, { foreignKey: 'address_id', as: 'orders' });
    };

    // Hook: ensure only one default address per user
    Address.addHook('beforeSave', async (address, options) => {
        if (address.is_default && address.changed('is_default')) {
            await Address.update(
                { is_default: false },
                {
                    where: {
                        user_id: address.user_id,
                        id: { [require('sequelize').Op.ne]: address.id },
                    },
                    transaction: options.transaction,
                }
            );
        }
    });

    return Address;
};
