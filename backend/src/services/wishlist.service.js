const { Wishlist, Product, Category } = require('../models');
const AppError = require('../utils/AppError');

const getWishlist = async (userId) => {
    const items = await Wishlist.findAll({
        where: { user_id: userId },
        include: [{
            model: Product,
            as: 'product',
            include: [{ model: Category, as: 'category', attributes: ['id', 'name'] }],
        }],
        order: [['created_at', 'DESC']],
    });

    return items.map(item => ({
        id: item.id,
        product: item.product,
        created_at: item.created_at,
    }));
};

const addToWishlist = async (userId, productId) => {
    const product = await Product.findByPk(productId);
    if (!product) throw new AppError('Sản phẩm không tồn tại', 404);

    const existing = await Wishlist.findOne({
        where: { user_id: userId, product_id: productId },
    });

    if (existing) throw new AppError('Sản phẩm đã có trong danh sách yêu thích', 409);

    const item = await Wishlist.create({ user_id: userId, product_id: productId });
    return item;
};

const removeFromWishlist = async (userId, productId) => {
    const deleted = await Wishlist.destroy({
        where: { user_id: userId, product_id: productId },
    });

    if (!deleted) throw new AppError('Sản phẩm không có trong danh sách yêu thích', 404);
    return true;
};

const isInWishlist = async (userId, productId) => {
    const item = await Wishlist.findOne({
        where: { user_id: userId, product_id: productId },
    });
    return !!item;
};

module.exports = { getWishlist, addToWishlist, removeFromWishlist, isInWishlist };
