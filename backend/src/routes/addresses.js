const express = require('express');
const { authenticate } = require('../middleware/auth');
const addressController = require('../controllers/address.controller');

const router = express.Router();
router.use(authenticate);

router.get('/', addressController.getAddresses);
router.post('/', addressController.createAddress);
router.put('/:id', addressController.updateAddress);
router.delete('/:id', addressController.deleteAddress);
router.patch('/:id/default', addressController.setDefault);

module.exports = router;
