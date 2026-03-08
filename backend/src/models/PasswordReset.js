const { DataTypes } = require('sequelize');
const crypto = require('crypto');

module.exports = (sequelize) => {
    const PasswordReset = sequelize.define('PasswordReset', {
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
        otp: {
            type: DataTypes.STRING(6),
            allowNull: false,
        },
        reset_token: {
            type: DataTypes.STRING(64),
            allowNull: true,
            comment: 'Generated after OTP is verified, used to reset password',
        },
        expires_at: {
            type: DataTypes.DATE,
            allowNull: false,
        },
        used_at: {
            type: DataTypes.DATE,
            allowNull: true,
        },
        attempts: {
            type: DataTypes.INTEGER,
            allowNull: false,
            defaultValue: 0,
            comment: 'Number of OTP verification attempts',
        },
    }, {
        tableName: 'password_resets',
        timestamps: true,
        underscored: true,
        updatedAt: false,
        indexes: [
            { fields: ['user_id'] },
            { fields: ['reset_token'] },
        ],
    });

    PasswordReset.generateOTP = () => {
        return Math.floor(100000 + Math.random() * 900000).toString();
    };

    PasswordReset.generateResetToken = () => crypto.randomBytes(32).toString('hex');

    PasswordReset.associate = (models) => {
        PasswordReset.belongsTo(models.User, { foreignKey: 'user_id', as: 'user' });
    };

    return PasswordReset;
};
