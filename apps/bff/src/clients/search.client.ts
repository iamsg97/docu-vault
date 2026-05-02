import { HttpClient } from './http.client';

export class SearchClient extends HttpClient {
  constructor(baseUrl: string) {
    super(baseUrl, 'search-service');
  }

  search(query: string, token: string, requestId: string) {
    return this.get<unknown>('/search', {
      headers: this.headers(requestId, token),
      params: { q: query },
    });
  }

  suggest(prefix: string, token: string, requestId: string) {
    return this.get<unknown>('/search/suggest', {
      headers: this.headers(requestId, token),
      params: { q: prefix },
    });
  }
}
