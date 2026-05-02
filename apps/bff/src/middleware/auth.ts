import { Request, Response, NextFunction } from 'express';
import { UnauthorizedError } from '@docuvault/shared-utils';

// Guards protected routes by requiring a Bearer token in the Authorization header.
// The BFF does NOT verify JWT signatures — that responsibility belongs to auth-service.
// This middleware only ensures the header is present and well-formed before forwarding.
export const requireAuth = (req: Request, _res: Response, next: NextFunction): void => {
  const authorization = req.headers['authorization'];

  if (!authorization?.startsWith('Bearer ')) {
    return next(new UnauthorizedError('Missing or malformed Authorization header'));
  }

  next();
};
