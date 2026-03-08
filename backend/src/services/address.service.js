const { Address } = require('../models');
const { Op } = require('sequelize');
const AppError = require('../utils/AppError');

const getAddresses = async (userId) => {
    return Address.findAll({
        where: { user_id: userId },
        order: [['is_default', 'DESC'], ['created_at', 'DESC']],
    });
};

const createAddress = async (userId, data) => {
    const existingCount = await Address.count({ where: { user_id: userId } });
    const shouldBeDefault = data.is_default || existingCount === 0;

    if (shouldBeDefault) {
        await Address.update({ is_default: false }, { where: { user_id: userId } });
    }

    return Address.create({
        user_id: userId,
        recipient_name: data.recipient_name,
        phone: data.phone,
        address_line: data.address_line,
        ward: data.ward || null,
        district: data.district || null,
        city: data.city,
        is_default: shouldBeDefault,
    });
};

const updateAddress = async (userId, addressId, data) => {
    const address = await Address.findOne({ where: { id: addressId, user_id: userId } });
    if (!address) throw new AppError('Địa chỉ không tồn tại', 404);

    if (data.is_default && !address.is_default) {
        await Address.update({ is_default: false }, { where: { user_id: userId } });
    }

    await address.update({
        recipient_name: data.recipient_name || address.recipient_name,
        phone: data.phone || address.phone,
        address_line: data.address_line || address.address_line,
        ward: data.ward !== undefined ? data.ward : address.ward,
        district: data.district !== undefined ? data.district : address.district,
        city: data.city || address.city,
        is_default: data.is_default !== undefined ? data.is_default : address.is_default,
    });

    return address;
};

const deleteAddress = async (userId, addressId) => {
    const address = await Address.findOne({ where: { id: addressId, user_id: userId } });
    if (!address) throw new AppError('Địa chỉ không tồn tại', 404);

    const wasDefault = address.is_default;
    await address.destroy();

    if (wasDefault) {
        const nextAddress = await Address.findOne({
            where: { user_id: userId },
            order: [['created_at', 'DESC']],
        });
        if (nextAddress) await nextAddress.update({ is_default: true });
    }
};

const setDefaultAddress = async (userId, addressId) => {
    const address = await Address.findOne({ where: { id: addressId, user_id: userId } });
    if (!address) throw new AppError('Địa chỉ không tồn tại', 404);

    await Address.update({ is_default: false }, { where: { user_id: userId } });
    await address.update({ is_default: true });
    return address;
};

module.exports = { getAddresses, createAddress, updateAddress, deleteAddress, setDefaultAddress };
