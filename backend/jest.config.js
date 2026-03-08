module.exports = {
    testEnvironment: 'node',
    testMatch: ['**/__tests__/**/*.test.js', '**/*.test.js'],
    testPathIgnorePatterns: ['/node_modules/'],
    verbose: true,
    forceExit: true,
    detectOpenHandles: true,
    coverageDirectory: 'coverage',
    coveragePathIgnorePatterns: [
        '/node_modules/',
        '/src/seeders/',
        '/src/config/',
    ],
    collectCoverageFrom: [
        'src/services/**/*.js',
        'src/controllers/**/*.js',
        'src/middleware/**/*.js',
        'src/utils/**/*.js',
    ],
};
