const { Setting } = require('../models');
const logger = require('../utils/logger');

// In-memory cache
let configCache = null;
let cacheExpiry = 0;
const CACHE_TTL = 60 * 1000; // 1 minute

const DEFAULT_CONFIG = {
    shop: {
        name: 'TạpHóa Shop',
        phone: '0901234567',
        address: '123 Đường Nguyễn Huệ, Q.1, TP.HCM',
    },
    bank: {
        bankName: 'Vietcombank',
        accountNumber: '1234567890123',
        accountHolder: 'NGUYEN VAN A',
        branch: 'Chi nhánh TP.HCM',
    },
    shipping: {
        rules: [
            { min_order: 0, max_order: 100000, fee: 15000, label: 'Đơn < 100,000₫' },
            { min_order: 100000, max_order: 200000, fee: 10000, label: '100k - 200k' },
            { min_order: 200000, max_order: null, fee: 0, label: 'Đơn ≥ 200,000₫ (Miễn phí)' },
        ],
    },
};

const seedDefaults = async () => {
    for (const [group, value] of Object.entries(DEFAULT_CONFIG)) {
        const existing = await Setting.findOne({ where: { key: group } });
        if (!existing) {
            await Setting.create({ key: group, value, group });
            logger.info(`📋 Seeded default config: ${group}`);
        }
    }
};

const loadFromDB = async () => {
    const settings = await Setting.findAll();
    const config = {};
    for (const s of settings) {
        config[s.key] = s.value;
    }
    return Object.keys(config).length > 0 ? config : { ...DEFAULT_CONFIG };
};

const getConfig = async () => {
    const now = Date.now();
    if (configCache && now < cacheExpiry) return configCache;

    try {
        configCache = await loadFromDB();
        cacheExpiry = now + CACHE_TTL;
        return configCache;
    } catch (error) {
        logger.error('Failed to load config from DB, using defaults:', error.message);
        return { ...DEFAULT_CONFIG };
    }
};

// Synchronous version for backward compatibility (order.service.js)
// Returns cached value or defaults
const getConfigSync = () => {
    return configCache || { ...DEFAULT_CONFIG };
};

const updateConfig = async (updates) => {
    for (const [key, value] of Object.entries(updates)) {
        if (['shop', 'bank', 'shipping'].includes(key)) {
            const existing = await Setting.findOne({ where: { key } });
            if (existing) {
                // Deep merge
                const merged = { ...existing.value, ...value };
                await existing.update({ value: merged });
            } else {
                await Setting.create({ key, value, group: key });
            }
        }
    }

    // Invalidate cache
    configCache = null;
    cacheExpiry = 0;

    return getConfig();
};

const invalidateCache = () => {
    configCache = null;
    cacheExpiry = 0;
};

module.exports = { getConfig, getConfigSync, updateConfig, seedDefaults, invalidateCache, DEFAULT_CONFIG };
