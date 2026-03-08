const multer = require('multer');
const catchAsync = require('../utils/catchAsync');
const AppError = require('../utils/AppError');
const uploadService = require('../services/upload.service');

// Memory storage — file buffer sent to Cloudinary or saved locally
const storage = multer.memoryStorage();

const fileFilter = (req, file, cb) => {
    const allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
    if (allowedTypes.includes(file.mimetype)) cb(null, true);
    else cb(new AppError('Chỉ chấp nhận file ảnh (JPEG, PNG, GIF, WebP)', 400), false);
};

const upload = multer({
    storage,
    fileFilter,
    limits: { fileSize: 5 * 1024 * 1024 },
});

exports.uploadMiddleware = upload.single('image');

exports.uploadImage = catchAsync(async (req, res) => {
    if (!req.file) throw new AppError('Vui lòng chọn file ảnh', 400);

    const result = await uploadService.uploadImage(req.file);

    res.json({
        status: 'success',
        data: result,
    });
});

exports.handleMulterError = (err, req, res, next) => {
    if (err instanceof multer.MulterError) {
        if (err.code === 'LIMIT_FILE_SIZE') {
            return next(new AppError('File quá lớn (tối đa 5MB)', 400));
        }
        return next(new AppError(err.message, 400));
    }
    next(err);
};
