'use strict';

const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');

module.exports = {
    async up(queryInterface) {
        const now = new Date();

        // ─── 1. Seed Admin & Customer Users ───────────────────
        const adminId = uuidv4();
        const customerId = uuidv4();
        const passwordHash = await bcrypt.hash('123456', 10);

        await queryInterface.bulkInsert('users', [
            {
                id: adminId,
                name: 'Chủ Shop Tạp Hóa',
                email: 'admin@taphoa.vn',
                phone: '0901234567',
                password_hash: passwordHash,
                role: 'admin',
                is_active: true,
                created_at: now,
                updated_at: now,
            },
            {
                id: customerId,
                name: 'Nguyễn Văn Khách',
                email: 'khach@gmail.com',
                phone: '0987654321',
                password_hash: passwordHash,
                role: 'customer',
                is_active: true,
                created_at: now,
                updated_at: now,
            },
        ]);

        // ─── 2. Seed Categories ──────────────────────────────
        await queryInterface.bulkInsert('categories', [
            { id: 1, name: 'Đồ uống', slug: 'do-uong', is_active: true, sort_order: 1, created_at: now, updated_at: now },
            { id: 2, name: 'Gia vị', slug: 'gia-vi', is_active: true, sort_order: 2, created_at: now, updated_at: now },
            { id: 3, name: 'Mì - Bún - Phở', slug: 'mi-bun-pho', is_active: true, sort_order: 3, created_at: now, updated_at: now },
            { id: 4, name: 'Bánh kẹo', slug: 'banh-keo', is_active: true, sort_order: 4, created_at: now, updated_at: now },
            { id: 5, name: 'Sữa & Sản phẩm từ sữa', slug: 'sua-san-pham-tu-sua', is_active: true, sort_order: 5, created_at: now, updated_at: now },
            { id: 6, name: 'Đồ dùng gia đình', slug: 'do-dung-gia-dinh', is_active: true, sort_order: 6, created_at: now, updated_at: now },
            { id: 7, name: 'Chăm sóc cá nhân', slug: 'cham-soc-ca-nhan', is_active: true, sort_order: 7, created_at: now, updated_at: now },
        ]);

        // ─── 3. Seed Products ────────────────────────────────
        const products = [
            // Đồ uống
            { name: 'Coca-Cola lon 330ml', slug: 'coca-cola-lon-330ml', category_id: 1, price: 10000, compare_at_price: 12000, unit: 'lon', stock_quantity: 100 },
            { name: 'Pepsi lon 330ml', slug: 'pepsi-lon-330ml', category_id: 1, price: 10000, compare_at_price: null, unit: 'lon', stock_quantity: 80 },
            { name: 'Nước suối Aquafina 500ml', slug: 'nuoc-suoi-aquafina-500ml', category_id: 1, price: 5000, compare_at_price: null, unit: 'chai', stock_quantity: 200 },
            { name: 'Trà xanh 0 độ 500ml', slug: 'tra-xanh-0-do-500ml', category_id: 1, price: 10000, compare_at_price: null, unit: 'chai', stock_quantity: 60 },
            // Gia vị
            { name: 'Nước mắm Nam Ngư 500ml', slug: 'nuoc-mam-nam-ngu-500ml', category_id: 2, price: 25000, compare_at_price: 30000, unit: 'chai', stock_quantity: 40 },
            { name: 'Dầu ăn Tường An 1L', slug: 'dau-an-tuong-an-1l', category_id: 2, price: 42000, compare_at_price: null, unit: 'chai', stock_quantity: 30 },
            { name: 'Bột ngọt Ajinomoto 400g', slug: 'bot-ngot-ajinomoto-400g', category_id: 2, price: 28000, compare_at_price: null, unit: 'gói', stock_quantity: 50 },
            // Mì - Bún - Phở
            { name: 'Mì Hảo Hảo tôm chua cay', slug: 'mi-hao-hao-tom-chua-cay', category_id: 3, price: 4000, compare_at_price: null, unit: 'gói', stock_quantity: 300 },
            { name: 'Phở bò Vifon', slug: 'pho-bo-vifon', category_id: 3, price: 7000, compare_at_price: null, unit: 'gói', stock_quantity: 150 },
            // Bánh kẹo
            { name: 'Bánh Oreo hộp 133g', slug: 'banh-oreo-hop-133g', category_id: 4, price: 22000, compare_at_price: 25000, unit: 'hộp', stock_quantity: 25 },
            { name: 'Kẹo dẻo Trolli 100g', slug: 'keo-deo-trolli-100g', category_id: 4, price: 18000, compare_at_price: null, unit: 'gói', stock_quantity: 35 },
            // Sữa
            { name: 'Sữa tươi Vinamilk 1L', slug: 'sua-tuoi-vinamilk-1l', category_id: 5, price: 32000, compare_at_price: null, unit: 'hộp', stock_quantity: 20 },
            { name: 'Sữa đặc Ông Thọ 380g', slug: 'sua-dac-ong-tho-380g', category_id: 5, price: 18000, compare_at_price: null, unit: 'lon', stock_quantity: 40 },
        ];

        await queryInterface.bulkInsert('products', products.map((p) => ({
            id: uuidv4(),
            ...p,
            description: `Sản phẩm ${p.name} chất lượng cao, giá tốt nhất.`,
            gallery: JSON.stringify([]),
            is_active: true,
            sort_order: 0,
            created_at: now,
            updated_at: now,
        })));

        // ─── 4. Seed Address for Customer ─────────────────────
        await queryInterface.bulkInsert('addresses', [
            {
                id: uuidv4(),
                user_id: customerId,
                recipient_name: 'Nguyễn Văn Khách',
                phone: '0987654321',
                address_line: '123 Đường Nguyễn Huệ',
                ward: 'Phường Bến Nghé',
                district: 'Quận 1',
                city: 'TP. Hồ Chí Minh',
                is_default: true,
                created_at: now,
                updated_at: now,
            },
        ]);
    },

    async down(queryInterface) {
        await queryInterface.bulkDelete('addresses', null, {});
        await queryInterface.bulkDelete('products', null, {});
        await queryInterface.bulkDelete('categories', null, {});
        await queryInterface.bulkDelete('users', null, {});
    },
};
