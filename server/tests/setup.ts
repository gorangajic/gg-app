// Test setup file
process.env.NODE_ENV = 'test';
process.env.DATABASE_URL = process.env.TEST_DATABASE_URL || process.env.DATABASE_URL;
process.env.JWT_SECRET = 'test-jwt-secret';
process.env.SMTP_USER = '';
process.env.SMTP_PASS = '';

// Increase timeout for integration tests
jest.setTimeout(30000);
