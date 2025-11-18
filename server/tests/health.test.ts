import { GET } from '../src/app/api/health/route';
import { NextRequest } from 'next/server';

describe('Health Check Endpoint', () => {
  it('should return health status', async () => {
    const request = new NextRequest('http://localhost:3001/api/health');
    const response = await GET();

    expect(response.status).toBe(200);

    const data = await response.json();
    expect(data).toHaveProperty('status');
    expect(data).toHaveProperty('timestamp');
    expect(data).toHaveProperty('services');
    expect(data.services).toHaveProperty('database');
    expect(data.services).toHaveProperty('api');
  });

  it('should include uptime and version', async () => {
    const response = await GET();
    const data = await response.json();

    expect(data).toHaveProperty('uptime');
    expect(data).toHaveProperty('version');
    expect(data).toHaveProperty('environment');
    expect(typeof data.uptime).toBe('number');
  });
});
