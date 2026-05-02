// Runs before any test module is loaded (jest setupFiles).
// Sets required env vars so env.ts passes Zod validation on first import.
process.env.NODE_ENV = 'test';
process.env.PORT = '3000';
process.env.LOG_LEVEL = 'silent';
process.env.AUTH_SERVICE_URL = 'http://localhost:3001';
process.env.DOCUMENT_SERVICE_URL = 'http://localhost:3002';
process.env.PROCESSING_SERVICE_URL = 'http://localhost:3003';
process.env.SEARCH_SERVICE_URL = 'http://localhost:3004';
process.env.NOTIFICATION_SERVICE_URL = 'http://localhost:3005';
