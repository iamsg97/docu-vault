import { Router, Request, Response } from 'express';
import { AuthClient } from '../clients/auth.client';
import { asyncHandler } from '../middleware/asyncHandler';
import { requireAuth } from '../middleware/auth';

export const createAuthRouter = (client: AuthClient): Router => {
  const router = Router();

  router.post(
    '/signup',
    asyncHandler(async (req: Request, res: Response) => {
      const result = await client.signup(req.body, req.requestId);
      res.status(201).json(result);
    }),
  );

  router.post(
    '/login',
    asyncHandler(async (req: Request, res: Response) => {
      const result = await client.login(req.body, req.requestId);
      res.json(result);
    }),
  );

  router.post(
    '/refresh',
    asyncHandler(async (req: Request, res: Response) => {
      const result = await client.refresh(req.body.refreshToken, req.requestId);
      res.json(result);
    }),
  );

  router.get(
    '/me',
    requireAuth,
    asyncHandler(async (req: Request, res: Response) => {
      const result = await client.me(req.headers['authorization'] as string, req.requestId);
      res.json(result);
    }),
  );

  router.post(
    '/logout',
    requireAuth,
    asyncHandler(async (req: Request, res: Response) => {
      await client.logout(req.headers['authorization'] as string, req.requestId);
      res.status(204).send();
    }),
  );

  return router;
};
