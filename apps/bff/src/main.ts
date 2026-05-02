import { env } from './config/env';
import { createApp } from './app';
import { createLogger } from '@docuvault/shared-utils';

const logger = createLogger('bff');

const server = createApp().listen(env.PORT, () => {
  logger.info({ port: env.PORT, env: env.NODE_ENV }, 'BFF server started');
});

const shutdown = (signal: string): void => {
  logger.info({ signal }, 'Shutdown signal received — closing server');

  server.close(() => {
    logger.info('HTTP server closed');
    process.exit(0);
  });

  // Force-exit if graceful close hangs beyond 10 s (e.g. long-lived keep-alive connections)
  setTimeout(() => {
    logger.error('Graceful shutdown timed out — forcing exit');
    process.exit(1);
  }, 10_000).unref();
};

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
