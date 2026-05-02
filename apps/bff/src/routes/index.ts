import { Router } from 'express';
import { env } from '../config/env';
import { AuthClient } from '../clients/auth.client';
import { DocumentClient } from '../clients/document.client';
import { SearchClient } from '../clients/search.client';
import { NotificationClient } from '../clients/notification.client';
import { createAuthRouter } from './auth.routes';
import { createDocumentsRouter } from './documents.routes';
import { createSearchRouter } from './search.routes';
import { createNotificationsRouter } from './notifications.routes';

// Service clients are singletons — one instance per downstream service,
// shared across all requests via closure. Avoids re-creating axios instances per request.
export const createRouter = (): Router => {
  const router = Router();

  const authClient = new AuthClient(env.AUTH_SERVICE_URL);
  const documentClient = new DocumentClient(env.DOCUMENT_SERVICE_URL);
  const searchClient = new SearchClient(env.SEARCH_SERVICE_URL);
  const notificationClient = new NotificationClient(env.NOTIFICATION_SERVICE_URL);

  router.use('/auth', createAuthRouter(authClient));
  router.use('/documents', createDocumentsRouter(documentClient));
  router.use('/search', createSearchRouter(searchClient));
  router.use('/notifications', createNotificationsRouter(notificationClient));

  return router;
};
