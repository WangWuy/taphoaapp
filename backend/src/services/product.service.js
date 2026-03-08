const { Op } = require('sequelize');
const { Product, Category } = require('../models');
const AppError = require('../utils/AppError');
const { generateSlug } = require('../utils/slug');

const listProducts = async ({ category_id, search, page = 1, limit = 50 }) => {
    const where = { is_active: true };
    if (category_id) where.category_id = category_id;
    if (search) {
        where[Op.or] = [
            { name: { [Op.iLike]: `%${search}%` } },
            { description: { [Op.iLike]: `%${search}%` } },
        ];
    }

    const offset = (parseInt(page) - 1) * parseInt(limit);
    const { count, rows } = await Product.findAndCountAll({
        where,
        include: [{ model: Category, as: 'category', attributes: ['id', 'name', 'slug'] }],
        order: [['sort_order', 'ASC'], ['created_at', 'DESC']],
        limit: parseInt(limit),
        offset,
    });

    return {
        data: rows,
        pagination: {
            total: count,
            page: parseInt(page),
            limit: parseInt(limit),
            totalPages: Math.ceil(count / parseInt(limit)),
        },
    };
};

const getProduct = async (id) => {
    const product = await Product.findByPk(id, {
        include: [{ model: Category, as: 'category', attributes: ['id', 'name', 'slug'] }],
    });
    if (!product) throw new AppError('Sản phẩm không tồn tại', 404);
    return product;
};

// Admin methods
const adminListProducts = async ({ category_id, search, is_active, stock_status }) => {
    const where = {};
    if (category_id) where.category_id = category_id;
    if (search) where.name = { [Op.iLike]: `%${search}%` };
    if (is_active !== undefined) where.is_active = is_active === 'true';
    if (stock_status === 'out') where.stock_quantity = 0;
    else if (stock_status === 'low') where.stock_quantity = { [Op.between]: [1, 10] };

    return Product.findAll({
        where,
        include: [{ model: Category, as: 'category', attributes: ['id', 'name'] }],
        order: [['created_at', 'DESC']],
    });
};

const getInventory = async ({ stock_status, category_id, search }) => {
    const where = {};
    if (stock_status === 'out_of_stock') where.stock_quantity = 0;
    else if (stock_status === 'low_stock') where.stock_quantity = { [Op.between]: [1, 10] };
    else if (stock_status === 'in_stock') where.stock_quantity = { [Op.gt]: 10 };
    if (category_id) where.category_id = category_id;
    if (search) where.name = { [Op.iLike]: `%${search}%` };

    const products = await Product.findAll({
        where,
        attributes: ['id', 'name', 'image_url', 'stock_quantity', 'unit', 'price', 'is_active'],
        include: [{ model: Category, as: 'category', attributes: ['id', 'name'] }],
        order: [['stock_quantity', 'ASC'], ['name', 'ASC']],
    });

    const allProducts = await Product.findAll({ attributes: ['stock_quantity'] });
    const summary = {
        total: allProducts.length,
        outOfStock: allProducts.filter(p => p.stock_quantity === 0).length,
        lowStock: allProducts.filter(p => p.stock_quantity > 0 && p.stock_quantity <= 10).length,
        inStock: allProducts.filter(p => p.stock_quantity > 10).length,
    };

    return { data: products, summary };
};

const createProduct = async (data) => {
    const slug = generateSlug(data.name);
    const product = await Product.create({
        ...data,
        slug,
        description: data.description || `Sản phẩm ${data.name} chất lượng cao.`,
        compare_at_price: data.compare_at_price || null,
        cost_price: data.cost_price || null,
        unit: data.unit || 'cái',
        stock_quantity: data.stock_quantity || 0,
        category_id: data.category_id || null,
        image_url: data.image_url || null,
        is_active: data.is_active !== undefined ? data.is_active : true,
    });

    return Product.findByPk(product.id, {
        include: [{ model: Category, as: 'category', attributes: ['id', 'name'] }],
    });
};

const updateProduct = async (id, data) => {
    const product = await Product.findByPk(id);
    if (!product) throw new AppError('Sản phẩm không tồn tại', 404);

    await product.update({
        name: data.name || product.name,
        description: data.description !== undefined ? data.description : product.description,
        price: data.price !== undefined ? data.price : product.price,
        compare_at_price: data.compare_at_price !== undefined ? data.compare_at_price : product.compare_at_price,
        cost_price: data.cost_price !== undefined ? data.cost_price : product.cost_price,
        unit: data.unit || product.unit,
        stock_quantity: data.stock_quantity !== undefined ? data.stock_quantity : product.stock_quantity,
        category_id: data.category_id !== undefined ? data.category_id : product.category_id,
        image_url: data.image_url !== undefined ? data.image_url : product.image_url,
        is_active: data.is_active !== undefined ? data.is_active : product.is_active,
    });

    return Product.findByPk(product.id, {
        include: [{ model: Category, as: 'category', attributes: ['id', 'name'] }],
    });
};

const updateStock = async (id, { quantity, adjustment }) => {
    const product = await Product.findByPk(id);
    if (!product) throw new AppError('Sản phẩm không tồn tại', 404);

    if (adjustment !== undefined) {
        const newQty = product.stock_quantity + parseInt(adjustment);
        if (newQty < 0) throw new AppError('Số lượng tồn kho không đủ', 400);
        await product.update({ stock_quantity: newQty });
    } else {
        const qty = parseInt(quantity);
        if (qty < 0) throw new AppError('Số lượng không được âm', 400);
        await product.update({ stock_quantity: qty });
    }

    return product;
};

const deleteProduct = async (id) => {
    const product = await Product.findByPk(id);
    if (!product) throw new AppError('Sản phẩm không tồn tại', 404);
    await product.update({ is_active: false });
};

const toggleActive = async (id) => {
    const product = await Product.findByPk(id);
    if (!product) throw new AppError('Sản phẩm không tồn tại', 404);
    await product.update({ is_active: !product.is_active });
    return Product.findByPk(id, {
        include: [{ model: Category, as: 'category', attributes: ['id', 'name'] }],
    });
};

module.exports = {
    listProducts, getProduct,
    adminListProducts, getInventory,
    createProduct, updateProduct, updateStock, deleteProduct, toggleActive,
};
