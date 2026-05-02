import { HttpClient } from './http.client';

export class NotificationClient extends HttpClient {
  constructor(baseUrl: string) {
    super(baseUrl, 'notification-service');
  }

  listNotifications(token: string, requestId: string) {
    return this.get<unknown>('/notifications', {
      headers: this.headers(requestId, token),
    });
  }

  markAsRead(id: string, token: string, requestId: string) {
    return this.patch<void>(`/notifications/${id}/read`, {}, {
      headers: this.headers(requestId, token),
    });
  }
}
