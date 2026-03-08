const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
    const Category = sequelize.define('Category', {
        id: {
            type: DataTypes.INTEGER,
            primaryKey: true,
            autoIncrement: true,
        },
        name: {
            type: DataTypes.STRING(100),
            allowNull: false,
            validate: {
                notEmpty: { msg: 'Tên danh mục không được để trống' },
            },
        },
        slug: {
            type: DataTypes.STRING(120),
            allowNull: false,
            unique: {
                msg: 'Slug danh mục đã tồn tại',
            },
        },
        image_url: {
            type: DataTypes.STRING(500),
            allowNull: true,
        },
        is_active: {
            type: DataTypes.BOOLEAN,
            allowNull: false,
            defaultValue: true,
        },
        sort_order: {
            type: DataTypes.INTEGER,
            allowNull: false,
            defaultValue: 0,
        },
    }, {
        tableName: 'categories',
        timestamps: true,
        underscored: true,
        scopes: {
            active: {
                where: { is_active: true },
                order: [['sort_order', 'ASC'], ['name', 'ASC']],
            },
        },
    });

    Category.associate = (models) => {
        Category.hasMany(models.Product, { foreignKey: 'category_id', as: 'products' });
    };

    return Category;
};
