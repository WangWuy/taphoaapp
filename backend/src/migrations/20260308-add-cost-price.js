'use strict';

module.exports = {
    async up(queryInterface, Sequelize) {
        // 1. Add cost_price column
        await queryInterface.addColumn('products', 'cost_price', {
            type: Sequelize.INTEGER,
            allowNull: true,
            defaultValue: null,
        });

        // 2. Swap price <-> compare_at_price for existing sale products
        // OLD logic: compare_at_price > price = on sale (Shopify style)
        // NEW logic: compare_at_price < price = on sale (traditional style)
        // So swap the values: price becomes the higher (regular), compare_at_price becomes the lower (sale)
        await queryInterface.sequelize.query(`
            UPDATE products 
            SET price = compare_at_price, 
                compare_at_price = price 
            WHERE compare_at_price IS NOT NULL 
              AND compare_at_price > price
        `);
    },

    async down(queryInterface) {
        // Reverse the swap
        await queryInterface.sequelize.query(`
            UPDATE products 
            SET price = compare_at_price, 
                compare_at_price = price 
            WHERE compare_at_price IS NOT NULL 
              AND compare_at_price < price
        `);

        await queryInterface.removeColumn('products', 'cost_price');
    },
};
