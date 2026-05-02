import pino from 'pino';

// Factory — each service/module gets its own named logger.
// In non-production, uses pino-pretty for human-readable output.
// In production, emits structured JSON (CloudWatch picks it up automatically).
export const createLogger = (name: string) =>
  pino({
    name,
    level: process.env.LOG_LEVEL ?? 'info',
    ...(process.env.NODE_ENV !== 'production' && {
      transport: {
        target: 'pino-pretty',
        options: { colorize: true, ignore: 'pid,hostname' },
      },
    }),
  });
