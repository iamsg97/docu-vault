import axios, { AxiosInstance, AxiosRequestConfig, isAxiosError } from 'axios';
import { AppError, ServiceUnavailableError, createLogger } from '@docuvault/shared-utils';

const logger = createLogger('bff:http-client');

// Base class for all downstream service clients.
// Handles: request-ID forwarding, auth-token forwarding, error translation.
// Each service client extends this and adds typed methods for its endpoints.
export abstract class HttpClient {
  protected readonly axios: AxiosInstance;

  constructor(
    protected readonly baseUrl: string,
    protected readonly serviceName: string,
  ) {
    this.axios = axios.create({
      baseURL: baseUrl,
      timeout: 10_000,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  // Builds the headers forwarded to every downstream request.
  protected headers(requestId: string, authToken?: string): Record<string, string> {
    const h: Record<string, string> = { 'X-Request-Id': requestId };
    if (authToken) h['Authorization'] = authToken;
    return h;
  }

  // Translates axios errors into typed AppErrors so the error handler can produce
  // a consistent response. Network failures become 503; upstream HTTP errors are
  // re-thrown preserving the original status code and body.
  private translate(err: unknown): never {
    if (isAxiosError(err)) {
      if (!err.response) {
        logger.warn({ service: this.serviceName }, 'Downstream service unreachable');
        throw new ServiceUnavailableError(`${this.serviceName} is currently unavailable`);
      }
      const { status, data } = err.response;
      throw new AppError(
        status,
        (data as { error?: string })?.error ?? 'UPSTREAM_ERROR',
        (data as { message?: string })?.message ?? 'Upstream service error',
        (data as { details?: Array<{ field: string; issue: string }> })?.details,
      );
    }
    throw err;
  }

  protected async get<T>(path: string, config?: AxiosRequestConfig): Promise<T> {
    try {
      const { data } = await this.axios.get<T>(path, config);
      return data;
    } catch (err) {
      this.translate(err);
    }
  }

  protected async post<T>(path: string, body: unknown, config?: AxiosRequestConfig): Promise<T> {
    try {
      const { data } = await this.axios.post<T>(path, body, config);
      return data;
    } catch (err) {
      this.translate(err);
    }
  }

  protected async put<T>(path: string, body: unknown, config?: AxiosRequestConfig): Promise<T> {
    try {
      const { data } = await this.axios.put<T>(path, body, config);
      return data;
    } catch (err) {
      this.translate(err);
    }
  }

  protected async patch<T>(path: string, body: unknown, config?: AxiosRequestConfig): Promise<T> {
    try {
      const { data } = await this.axios.patch<T>(path, body, config);
      return data;
    } catch (err) {
      this.translate(err);
    }
  }

  protected async delete<T>(path: string, config?: AxiosRequestConfig): Promise<T> {
    try {
      const { data } = await this.axios.delete<T>(path, config);
      return data;
    } catch (err) {
      this.translate(err);
    }
  }
}
