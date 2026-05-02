import { Request, Response, NextFunction, RequestHandler } from 'express';

// Wraps an async route handler so that any rejected promise is forwarded to
// Express's error handler via next(err) instead of causing an unhandled rejection.
export const asyncHandler =
  (fn: RequestHandler): RequestHandler =>
  (req: Request, res: Response, next: NextFunction): void => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
