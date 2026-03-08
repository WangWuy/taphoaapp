const express = require('express');
const { authenticate, requireAdmin } = require('../../middleware/auth');
const validate = require('../../middleware/validate');
const { createCategory, updateCategory } = require('../../validators/product.validator');
const categoryController = require('../../controllers/category.controller');

const router = express.Router();
router.use(authenticate, requireAdmin);

router.get('/', categoryController.adminListCategories);
router.post('/', validate(createCategory), categoryController.createCategory);
router.put('/:id', validate(updateCategory), categoryController.updateCategory);
router.delete('/:id', categoryController.deleteCategory);

module.exports = router;
