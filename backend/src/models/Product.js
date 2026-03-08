const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
    const Product = sequelize.define('Product', {
        id: {
            type: DataTypes.UUID,
            defaultValue: DataTypes.UUIDV4,
            primaryKey: true,
        },
        category_id: {
            type: DataTypes.INTEGER,
            allowNull: true,
            references: {
                model: 'categories',
                key: 'id',
            },
        },
        name: {
            type: DataTypes.STRING(200),
            allowNull: false,
            validate: {
                notEmpty: { msg: 'Tên sản phẩm không được để trống' },
            },
        },
        slug: {
            type: DataTypes.STRING(220),
            allowNull: false,
            unique: {
                msg: 'Slug sản phẩm đã tồn tại',
            },
        },
        description: {
            type: DataTypes.TEXT,
            allowNull: true,
        },
        price: {
            type: DataTypes.INTEGER,
            allowNull: false,
            validate: {
                min: { args: [0], msg: 'Giá không được âm' },
            },
        },
        compare_at_price: {
            type: DataTypes.INTEGER,
            allowNull: true,
            validate: {
                min: { args: [0], msg: 'Giá so sánh không được âm' },
            },
        },
        unit: {
            type: DataTypes.STRING(30),
            allowNull: false,
            defaultValue: 'cái',
        },
        stock_quantity: {
            type: DataTypes.INTEGER,
            allowNull: false,
            defaultValue: 0,
            validate: {
                min: { args: [0], msg: 'Số lượng tồn kho không được âm' },
            },
        },
        image_url: {
            type: DataTypes.STRING(500),
            allowNull: true,
        },
        gallery: {
            type: DataTypes.JSONB,
            allowNull: true,
            defaultValue: [],
            comment: 'Array of additional image URLs',
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
        tableName: 'products',
        timestamps: true,
        underscored: true,
        scopes: {
            active: {
                where: { is_active: true },
            },
            inStock: {
                where: {
                    is_active: true,
                    stock_quantity: { [require('sequelize').Op.gt]: 0 },
                },
            },
        },
    });

    // Virtual field: check if on sale
    Product.prototype.isOnSale = function () {
        return this.compare_at_price && this.compare_at_price > this.price;
    };

    // Virtual field: discount percentage
    Product.prototype.discountPercent = function () {
        if (!this.isOnSale()) return 0;
        return Math.round((1 - this.price / this.compare_at_price) * 100);
    };

    Product.associate = (models) => {
        Product.belongsTo(models.Category, { foreignKey: 'category_id', as: 'category' });
        Product.hasMany(models.CartItem, { foreignKey: 'product_id', as: 'cartItems' });
        Product.hasMany(models.OrderItem, { foreignKey: 'product_id', as: 'orderItems' });
    };

    return Product;
};
