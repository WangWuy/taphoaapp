const { CartItem, Product } = require('../models');
const AppError = require('../utils/AppError');

const getCart = async (userId) => {
    return CartItem.findAll({
        where: { user_id: userId },
        include: [{ model: Product, as: 'product' }],
        order: [['created_at', 'DESC']],
    });
};

const addToCart = async (userId, { product_id, quantity = 1 }) => {
    const product = await Product.findByPk(product_id);
    if (!product || !product.is_active) throw new AppError('Sản phẩm không tồn tại', 404);
    if (product.stock_quantity < quantity) {
        throw new AppError(`Chỉ còn ${product.stock_quantity} sản phẩm trong kho`, 400);
    }

    const existing = await CartItem.findOne({ where: { user_id: userId, product_id } });

    let cartItem;
    if (existing) {
        const newQty = existing.quantity + quantity;
        if (newQty > product.stock_quantity) {
            throw new AppError(`Chỉ còn ${product.stock_quantity} sản phẩm trong kho`, 400);
        }
        existing.quantity = newQty;
        await existing.save();
        cartItem = existing;
    } else {
        cartItem = await CartItem.create({ user_id: userId, product_id, quantity });
    }

    return CartItem.findByPk(cartItem.id, {
        include: [{ model: Product, as: 'product' }],
    });
};

const updateCartItem = async (userId, itemId, { quantity }) => {
    const cartItem = await CartItem.findOne({
        where: { id: itemId, user_id: userId },
        include: [{ model: Product, as: 'product' }],
    });
    if (!cartItem) throw new AppError('Sản phẩm không có trong giỏ hàng', 404);

    if (quantity > cartItem.product.stock_quantity) {
        throw new AppError(`Chỉ còn ${cartItem.product.stock_quantity} sản phẩm trong kho`, 400);
    }

    if (quantity <= 0) {
        await cartItem.destroy();
        return null;
    }

    cartItem.quantity = quantity;
    await cartItem.save();

    return CartItem.findByPk(cartItem.id, {
        include: [{ model: Product, as: 'product' }],
    });
};

const deleteCartItem = async (userId, itemId) => {
    const cartItem = await CartItem.findOne({ where: { id: itemId, user_id: userId } });
    if (!cartItem) throw new AppError('Sản phẩm không có trong giỏ hàng', 404);
    await cartItem.destroy();
};

const clearCart = async (userId) => {
    await CartItem.destroy({ where: { user_id: userId } });
};

module.exports = { getCart, addToCart, updateCartItem, deleteCartItem, clearCart };
