const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
    const DeviceToken = sequelize.define('DeviceToken', {
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
        fcm_token: {
            type: DataTypes.TEXT,
            allowNull: false,
        },
        device_type: {
            type: DataTypes.ENUM('ios', 'android', 'web'),
            allowNull: false,
            defaultValue: 'android',
        },
        is_active: {
            type: DataTypes.BOOLEAN,
            allowNull: false,
            defaultValue: true,
        },
    }, {
        tableName: 'device_tokens',
        timestamps: true,
        underscored: true,
        indexes: [
            { fields: ['user_id'] },
            { fields: ['fcm_token'], unique: true },
        ],
    });

    DeviceToken.associate = (models) => {
        DeviceToken.belongsTo(models.User, { foreignKey: 'user_id', as: 'user' });
    };

    return DeviceToken;
};
