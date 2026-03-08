const cloudinary = require('cloudinary').v2;
const streamifier = require('streamifier');
const path = require('path');
const fs = require('fs');
const logger = require('../utils/logger');

const isCloudinaryConfigured = () => {
    return !!(process.env.CLOUDINARY_CLOUD_NAME &&
        process.env.CLOUDINARY_API_KEY &&
        process.env.CLOUDINARY_API_SECRET);
};

// Configure cloudinary if credentials exist
if (isCloudinaryConfigured()) {
    cloudinary.config({
        cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
        api_key: process.env.CLOUDINARY_API_KEY,
        api_secret: process.env.CLOUDINARY_API_SECRET,
    });
    logger.info('☁️  Cloudinary configured');
}

const uploadToCloudinary = (fileBuffer, folder = 'taphoa') => {
    return new Promise((resolve, reject) => {
        logger.debug(`☁️  Cloudinary upload starting (${fileBuffer.length} bytes)`);

        // Timeout safety net — 30s max for Cloudinary upload
        const timeout = setTimeout(() => {
            reject(new Error('Cloudinary upload timeout (30s)'));
        }, 30000);

        const stream = cloudinary.uploader.upload_stream(
            {
                folder,
                resource_type: 'image',
                transformation: [
                    { width: 1024, height: 1024, crop: 'limit' },
                    { quality: 'auto', fetch_format: 'auto' },
                ],
            },
            (error, result) => {
                clearTimeout(timeout);
                if (error) {
                    logger.error('☁️  Cloudinary upload error:', error.message);
                    reject(error);
                } else {
                    logger.debug(`☁️  Cloudinary upload success: ${result.secure_url}`);
                    resolve(result);
                }
            }
        );

        stream.on('error', (err) => {
            clearTimeout(timeout);
            logger.error('☁️  Cloudinary stream error:', err.message);
            reject(err);
        });

        streamifier.createReadStream(fileBuffer).pipe(stream);
    });
};

const uploadToLocal = (file) => {
    const uploadsDir = path.join(__dirname, '../../uploads');
    if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir, { recursive: true });

    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const filename = `${uniqueSuffix}${path.extname(file.originalname)}`;
    const filePath = path.join(uploadsDir, filename);

    fs.writeFileSync(filePath, file.buffer);
    return { url: `/uploads/${filename}`, filename, size: file.size };
};

const uploadImage = async (file) => {
    logger.info(`📤 Upload request: ${file.originalname} (${file.size} bytes, ${file.mimetype})`);

    if (isCloudinaryConfigured()) {
        try {
            const result = await uploadToCloudinary(file.buffer);
            return {
                url: result.secure_url,
                public_id: result.public_id,
                size: result.bytes,
                width: result.width,
                height: result.height,
            };
        } catch (error) {
            logger.error(`📤 Upload failed: ${error.message}`);
            throw error;
        }
    }

    // Fallback to local storage in development
    logger.debug('📁 Using local upload (Cloudinary not configured)');
    return uploadToLocal(file);
};

const deleteImage = async (publicId) => {
    if (!isCloudinaryConfigured() || !publicId) return;
    try {
        await cloudinary.uploader.destroy(publicId);
    } catch (error) {
        logger.error('Delete image error:', error.message);
    }
};

module.exports = { uploadImage, deleteImage, isCloudinaryConfigured };
