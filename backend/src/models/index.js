const { Sequelize } = require('sequelize');
const config = require('../config/database');

const env = process.env.NODE_ENV || 'development';
const dbConfig = config[env];

const sequelize = dbConfig.use_env_variable
    ? new Sequelize(process.env[dbConfig.use_env_variable], {
        dialect: dbConfig.dialect,
        logging: dbConfig.logging,
        define: dbConfig.define,
        dialectOptions: dbConfig.dialectOptions || {},
    })
    : new Sequelize(dbConfig);

// Import models
const User = require('./User')(sequelize);
const Category = require('./Category')(sequelize);
const Product = require('./Product')(sequelize);
const Address = require('./Address')(sequelize);
const CartItem = require('./CartItem')(sequelize);
const Order = require('./Order')(sequelize);
const OrderItem = require('./OrderItem')(sequelize);
const Notification = require('./Notification')(sequelize);
const RefreshToken = require('./RefreshToken')(sequelize);
const PasswordReset = require('./PasswordReset')(sequelize);
const Setting = require('./Setting')(sequelize);
const DeviceToken = require('./DeviceToken')(sequelize);

const models = {
    User,
    Category,
    Product,
    Address,
    CartItem,
    Order,
    OrderItem,
    Notification,
    RefreshToken,
    PasswordReset,
    Setting,
    DeviceToken,
};

// Run associations
Object.values(models).forEach((model) => {
    if (model.associate) {
        model.associate(models);
    }
});

module.exports = {
    sequelize,
    Sequelize,
    ...models,
};
