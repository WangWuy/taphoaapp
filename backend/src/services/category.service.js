const { Category, Product } = require('../models');
const AppError = require('../utils/AppError');
const { generateSlug } = require('../utils/slug');

const listActiveCategories = async () => {
    return Category.scope('active').findAll();
};

const adminListCategories = async () => {
    const categories = await Category.findAll({
        order: [['sort_order', 'ASC'], ['name', 'ASC']],
    });

    return Promise.all(categories.map(async (cat) => {
        const productCount = await Product.count({ where: { category_id: cat.id } });
        return { ...cat.toJSON(), productCount };
    }));
};

const createCategory = async (data) => {
    const slug = generateSlug(data.name);

    // Auto-increment sort_order if not provided
    let sortOrder = data.sort_order;
    if (sortOrder === undefined || sortOrder === null || sortOrder === 0) {
        const maxOrder = await Category.max('sort_order') || 0;
        sortOrder = maxOrder + 1;
    }

    return Category.create({
        name: data.name,
        slug,
        image_url: data.image_url || null,
        is_active: data.is_active !== undefined ? data.is_active : true,
        sort_order: sortOrder,
    });
};

const updateCategory = async (id, data) => {
    const category = await Category.findByPk(id);
    if (!category) throw new AppError('Danh mục không tồn tại', 404);

    const newSortOrder = data.sort_order !== undefined ? data.sort_order : category.sort_order;

    // If sort_order changed, shift others to avoid duplicates
    if (data.sort_order !== undefined && data.sort_order !== category.sort_order) {
        const { Op } = require('sequelize');
        await Category.increment('sort_order', {
            by: 1,
            where: {
                sort_order: { [Op.gte]: newSortOrder },
                id: { [Op.ne]: id },
            },
        });
    }

    await category.update({
        name: data.name || category.name,
        image_url: data.image_url !== undefined ? data.image_url : category.image_url,
        is_active: data.is_active !== undefined ? data.is_active : category.is_active,
        sort_order: newSortOrder,
    });

    return category;
};

const deleteCategory = async (id) => {
    const category = await Category.findByPk(id);
    if (!category) throw new AppError('Danh mục không tồn tại', 404);

    const productCount = await Product.count({ where: { category_id: category.id } });
    if (productCount > 0) {
        await category.update({ is_active: false });
        return { message: `Đã ẩn danh mục (có ${productCount} sản phẩm)` };
    }

    await category.destroy();
    return { message: 'Đã xóa danh mục' };
};

module.exports = { listActiveCategories, adminListCategories, createCategory, updateCategory, deleteCategory };
