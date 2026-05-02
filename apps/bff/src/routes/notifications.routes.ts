import { Router, Request, Response } from 'express';
import { NotificationClient } from '../clients/notification.client';
import { asyncHandler } from '../middleware/asyncHandler';
import { requireAuth } from '../middleware/auth';

export const createNotificationsRouter = (client: NotificationClient): Router => {
  const router = Router();
  router.use(requireAuth);

  const token = (req: Request) => req.headers['authorization'] as string;
  const id = (req: Request) => req.params['id'] as string;

  router.get(
    '/',
    asyncHandler(async (req: Request, res: Response) => {
      const result = await client.listNotifications(token(req), req.requestId);
      res.json(result);
    }),
  );

  router.patch(
    '/:id/read',
    asyncHandler(async (req: Request, res: Response) => {
      await client.markAsRead(id(req), token(req), req.requestId);
      res.status(204).send();
    }),
  );

  return router;
};
