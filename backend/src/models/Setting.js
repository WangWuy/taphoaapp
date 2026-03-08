const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
    const Setting = sequelize.define('Setting', {
        id: {
            type: DataTypes.INTEGER,
            primaryKey: true,
            autoIncrement: true,
        },
        key: {
            type: DataTypes.STRING(100),
            allowNull: false,
            unique: true,
        },
        value: {
            type: DataTypes.JSONB,
            allowNull: false,
            defaultValue: {},
        },
        group: {
            type: DataTypes.STRING(50),
            allowNull: false,
            defaultValue: 'general',
            comment: 'Group settings by category: shop, bank, shipping, etc.',
        },
    }, {
        tableName: 'settings',
        timestamps: true,
        underscored: true,
        indexes: [
            { fields: ['key'], unique: true },
            { fields: ['group'] },
        ],
    });

    return Setting;
};
