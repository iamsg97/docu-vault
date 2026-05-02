import { Router, Request, Response } from 'express';
import { SearchClient } from '../clients/search.client';
import { asyncHandler } from '../middleware/asyncHandler';
import { requireAuth } from '../middleware/auth';

export const createSearchRouter = (client: SearchClient): Router => {
  const router = Router();
  router.use(requireAuth);

  const token = (req: Request) => req.headers['authorization'] as string;

  router.get(
    '/',
    asyncHandler(async (req: Request, res: Response) => {
      const result = await client.search(req.query.q as string, token(req), req.requestId);
      res.json(result);
    }),
  );

  router.get(
    '/suggest',
    asyncHandler(async (req: Request, res: Response) => {
      const result = await client.suggest(req.query.q as string, token(req), req.requestId);
      res.json(result);
    }),
  );

  return router;
};
