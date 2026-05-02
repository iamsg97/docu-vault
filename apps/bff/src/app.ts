import express, { Application, Request, Response } from 'express';
import pinoHttp from 'pino-http';
import { createLogger } from '@docuvault/shared-utils';
import { requestIdMiddleware } from './middleware/requestId';
import { errorHandler } from './middleware/errorHandler';
import { createRouter } from './routes';

const logger = createLogger('bff');

export const createApp = (): Application => {
  const app = express();

  // Parse JSON bodies up to 1 MB
  app.use(express.json({ limit: '1mb' }));

  // Structured HTTP request/response logging via pino
  app.use(pinoHttp({ logger }));

  // Attach request ID to every request and echo it in the response header
  app.use(requestIdMiddleware);

  // Health check — no auth, no version prefix.
  // Hit by ECS health checks and the ALB target group health check.
  app.get('/health', (_req: Request, res: Response) => {
    res.json({ status: 'ok', service: 'bff', timestamp: new Date().toISOString() });
  });

  // All API routes are versioned under /api/v1
  app.use('/api/v1', createRouter());

  // 404 catch-all — must come after all route registrations
  app.use((_req: Request, res: Response) => {
    res.status(404).json({
      statusCode: 404,
      error: 'NOT_FOUND',
      message: 'The requested route does not exist',
    });
  });

  // Global error handler — must be last middleware and must have 4 arguments
  app.use(errorHandler);

  return app;
};
