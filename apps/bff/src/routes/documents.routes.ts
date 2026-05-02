import { Router, Request, Response } from 'express';
import { DocumentClient } from '../clients/document.client';
import { asyncHandler } from '../middleware/asyncHandler';
import { requireAuth } from '../middleware/auth';

// All document routes require authentication
export const createDocumentsRouter = (client: DocumentClient): Router => {
  const router = Router();
  router.use(requireAuth);

  const token = (req: Request) => req.headers['authorization'] as string;
  // Express params are always strings at runtime; cast needed for @types/express v5
  const id = (req: Request) => req.params['id'] as string;

  router.post(
    '/',
    asyncHandler(async (req: Request, res: Response) => {
      const result = await client.createDocument(req.body, token(req), req.requestId);
      res.status(201).json(result);
    }),
  );

  router.get(
    '/',
    asyncHandler(async (req: Request, res: Response) => {
      const result = await client.listDocuments(
        req.query as Record<string, string>,
        token(req),
        req.requestId,
      );
      res.json(result);
    }),
  );

  router.get(
    '/:id',
    asyncHandler(async (req: Request, res: Response) => {
      const result = await client.getDocument(id(req), token(req), req.requestId);
      res.json(result);
    }),
  );

  router.put(
    '/:id',
    asyncHandler(async (req: Request, res: Response) => {
      const result = await client.updateDocument(
        id(req),
        req.body,
        token(req),
        req.requestId,
      );
      res.json(result);
    }),
  );

  router.delete(
    '/:id',
    asyncHandler(async (req: Request, res: Response) => {
      await client.deleteDocument(id(req), token(req), req.requestId);
      res.status(204).send();
    }),
  );

  router.post(
    '/:id/share',
    asyncHandler(async (req: Request, res: Response) => {
      await client.shareDocument(id(req), req.body, token(req), req.requestId);
      res.status(204).send();
    }),
  );

  router.get(
    '/:id/status',
    asyncHandler(async (req: Request, res: Response) => {
      const result = await client.getDocumentStatus(id(req), token(req), req.requestId);
      res.json(result);
    }),
  );

  return router;
};
