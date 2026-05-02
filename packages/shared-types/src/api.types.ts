// Standard error shape — every service must return this format on errors
export interface ApiErrorResponse {
  statusCode: number;
  error: string;
  message: string;
  details?: Array<{ field: string; issue: string }>;
}

// Cursor-based pagination response — never use offset-based pagination
export interface PaginatedResponse<T> {
  data: T[];
  cursor: string | null;
  hasMore: boolean;
}

export interface PaginationQuery {
  cursor?: string;
  limit?: number;
}
