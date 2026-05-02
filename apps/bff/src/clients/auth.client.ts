import { HttpClient } from './http.client';

interface SignupBody {
  email: string;
  password: string;
  name: string;
}

interface LoginBody {
  email: string;
  password: string;
}

export class AuthClient extends HttpClient {
  constructor(baseUrl: string) {
    super(baseUrl, 'auth-service');
  }

  signup(body: SignupBody, requestId: string) {
    return this.post<unknown>('/auth/signup', body, { headers: this.headers(requestId) });
  }

  login(body: LoginBody, requestId: string) {
    return this.post<unknown>('/auth/login', body, { headers: this.headers(requestId) });
  }

  refresh(refreshToken: string, requestId: string) {
    return this.post<unknown>('/auth/refresh', { refreshToken }, { headers: this.headers(requestId) });
  }

  me(token: string, requestId: string) {
    return this.get<unknown>('/auth/me', { headers: this.headers(requestId, token) });
  }

  logout(token: string, requestId: string) {
    return this.post<unknown>('/auth/logout', {}, { headers: this.headers(requestId, token) });
  }
}
