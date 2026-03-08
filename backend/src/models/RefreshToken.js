const { DataTypes } = require('sequelize');
const crypto = require('crypto');

module.exports = (sequelize) => {
    const RefreshToken = sequelize.define('RefreshToken', {
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
        token: {
            type: DataTypes.STRING(64),
            allowNull: false,
            unique: true,
        },
        expires_at: {
            type: DataTypes.DATE,
            allowNull: false,
        },
        revoked_at: {
            type: DataTypes.DATE,
            allowNull: true,
        },
    }, {
        tableName: 'refresh_tokens',
        timestamps: true,
        underscored: true,
        updatedAt: false,
        indexes: [
            { fields: ['token'] },
            { fields: ['user_id'] },
        ],
    });

    RefreshToken.generateToken = () => crypto.randomBytes(32).toString('hex');

    RefreshToken.createForUser = async function (userId, expiresInDays = 30) {
        // Revoke old tokens (keep max 5 active)
        const activeTokens = await this.findAll({
            where: { user_id: userId, revoked_at: null },
            order: [['created_at', 'ASC']],
        });
        if (activeTokens.length >= 5) {
            const toRevoke = activeTokens.slice(0, activeTokens.length - 4);
            for (const t of toRevoke) {
                await t.update({ revoked_at: new Date() });
            }
        }

        const token = this.generateToken();
        const expiresAt = new Date();
        expiresAt.setDate(expiresAt.getDate() + expiresInDays);

        return this.create({ user_id: userId, token, expires_at: expiresAt });
    };

    RefreshToken.associate = (models) => {
        RefreshToken.belongsTo(models.User, { foreignKey: 'user_id', as: 'user' });
    };

    return RefreshToken;
};
