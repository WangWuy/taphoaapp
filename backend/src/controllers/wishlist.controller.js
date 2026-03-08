const catchAsync = require('../utils/catchAsync');
const wishlistService = require('../services/wishlist.service');

exports.getWishlist = catchAsync(async (req, res) => {
    const items = await wishlistService.getWishlist(req.userId);
    res.json({ status: 'success', data: items });
});

exports.addToWishlist = catchAsync(async (req, res) => {
    await wishlistService.addToWishlist(req.userId, req.body.product_id);
    res.status(201).json({ status: 'success', message: 'Đã thêm vào yêu thích' });
});

exports.removeFromWishlist = catchAsync(async (req, res) => {
    await wishlistService.removeFromWishlist(req.userId, req.params.productId);
    res.json({ status: 'success', message: 'Đã xóa khỏi yêu thích' });
});
