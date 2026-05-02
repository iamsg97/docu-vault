import { Request, Response, NextFunction } from 'express';
import { v4 as uuidv4 } from 'uuid';

// Generates a unique request ID for every inbound request.
// Honours an existing X-Request-Id header (e.g. from ALB or upstream proxy).
// The ID is attached to req and echoed back as a response header for tracing.
export const requestIdMiddleware = (req: Request, res: Response, next: NextFunction): void => {
  req.requestId = (req.headers['x-request-id'] as string) ?? uuidv4();
  res.setHeader('X-Request-Id', req.requestId);
  next();
};
