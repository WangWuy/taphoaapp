#!/usr/bin/env node

/**
 * Pre-deploy checklist — validates the environment is configured correctly.
 * Run: node scripts/pre-deploy-check.js
 */

const checks = [];

function check(name, ok, detail = '') {
    checks.push({ name, ok, detail });
    const icon = ok ? '✅' : '❌';
    console.log(`${icon} ${name}${detail ? ` — ${detail}` : ''}`);
}

console.log('\n🔍 Pre-Deploy Checklist\n' + '─'.repeat(50));

// 1. NODE_ENV
check('NODE_ENV', process.env.NODE_ENV === 'production',
    `Current: ${process.env.NODE_ENV || 'not set'}`);

// 2. JWT_SECRET
const jwtSecret = process.env.JWT_SECRET || '';
check('JWT_SECRET strength',
    jwtSecret.length >= 32 && !jwtSecret.includes('dev') && !jwtSecret.includes('test'),
    jwtSecret.length < 32 ? 'Too short (min 32 chars)' : jwtSecret.includes('dev') ? 'Contains "dev"' : 'OK');

// 3. DATABASE_URL
const dbUrl = process.env.DATABASE_URL || '';
check('DATABASE_URL', !!dbUrl && dbUrl.startsWith('postgres'),
    dbUrl ? 'Set' : 'Missing');

// 4. ACCESS_TOKEN_EXPIRES_IN
const tokenExpiry = process.env.ACCESS_TOKEN_EXPIRES_IN || '';
check('ACCESS_TOKEN_EXPIRES_IN',
    tokenExpiry && !tokenExpiry.includes('d'),
    `Current: ${tokenExpiry || '15m (default)'}`);

// 5. Cloudinary
const cloudinary = !!(process.env.CLOUDINARY_CLOUD_NAME && process.env.CLOUDINARY_API_KEY);
check('Cloudinary configured', cloudinary,
    cloudinary ? 'Ready' : 'Not set — uploads will fail');

// 6. Firebase
const firebase = !!(process.env.FIREBASE_SERVICE_ACCOUNT || process.env.FIREBASE_PROJECT_ID);
check('Firebase configured', firebase,
    firebase ? 'Ready' : 'Not set — push notifications disabled');

// 7. CORS
const cors = process.env.CORS_ORIGINS;
check('CORS_ORIGINS', !!cors,
    cors ? cors : 'Not set — using wildcard (insecure)');

// Summary
console.log('\n' + '─'.repeat(50));
const passed = checks.filter(c => c.ok).length;
const total = checks.length;
const allPassed = passed === total;

console.log(`\n${allPassed ? '🚀' : '⚠️ '} ${passed}/${total} checks passed\n`);

if (!allPassed) {
    console.log('Required fixes:');
    checks.filter(c => !c.ok).forEach(c => console.log(`  • ${c.name}: ${c.detail}`));
    console.log('');
}

process.exit(allPassed ? 0 : 1);
