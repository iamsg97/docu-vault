import { Request, Response, NextFunction } from 'express';
import { AppError, createLogger } from '@docuvault/shared-utils';
import { ApiErrorResponse } from '@docuvault/shared-types';

const logger = createLogger('bff:error-handler');

// Global error handler — must be registered last and must declare all 4 arguments
// so Express recognises it as an error-handling middleware.
export const errorHandler = (
  err: unknown,
  req: Request,
  res: Response,
  _next: NextFunction,
): void => {
  if (err instanceof AppError) {
    const body: ApiErrorResponse = {
      statusCode: err.statusCode,
      error: err.error,
      message: err.message,
      ...(err.details && { details: err.details }),
    };
    res.status(err.statusCode).json(body);
    return;
  }

  // Unexpected errors — log with full context, return a safe generic 500
  logger.error({ err, requestId: req.requestId }, 'Unhandled error');

  res.status(500).json({
    statusCode: 500,
    error: 'INTERNAL_SERVER_ERROR',
    message: 'An unexpected error occurred',
  } satisfies ApiErrorResponse);
};
