const { generateSlug } = require('../../utils/slug');

describe('generateSlug', () => {
    test('should generate slug from Vietnamese text', () => {
        const slug = generateSlug('Nước mắm Nam Ngư');
        expect(slug).toMatch(/^nuoc-mam-nam-ngu-\d+$/);
    });

    test('should handle đ/Đ character', () => {
        const slug = generateSlug('Đồ uống');
        expect(slug).toMatch(/^do-uong-\d+$/);
    });

    test('should remove special characters', () => {
        const slug = generateSlug('Bánh & Kẹo (ngon)');
        expect(slug).toMatch(/^banh-keo-ngon-\d+$/);
    });

    test('should include timestamp suffix for uniqueness', () => {
        const slug = generateSlug('Test');
        // Format: text-timestamp
        const parts = slug.split('-');
        const timestamp = parts[parts.length - 1];
        expect(Number(timestamp)).toBeGreaterThan(0);
    });
});
