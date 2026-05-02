import request from 'supertest';
import { createApp } from '../src/app';

describe('GET /health', () => {
  it('returns 200 with service status', async () => {
    const app = createApp();
    const res = await request(app).get('/health');

    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({
      status: 'ok',
      service: 'bff',
    });
    expect(typeof res.body.timestamp).toBe('string');
  });
});

describe('GET /unknown-route', () => {
  it('returns 404 for unregistered routes', async () => {
    const app = createApp();
    const res = await request(app).get('/api/v1/unknown');

    expect(res.status).toBe(404);
    expect(res.body).toMatchObject({ statusCode: 404, error: 'NOT_FOUND' });
  });
});

describe('GET /api/v1/documents (unauthenticated)', () => {
  it('returns 401 when Authorization header is missing', async () => {
    const app = createApp();
    const res = await request(app).get('/api/v1/documents');

    expect(res.status).toBe(401);
    expect(res.body).toMatchObject({ statusCode: 401, error: 'UNAUTHORIZED' });
  });
});
