// Base class for all application errors.
// statusCode maps to the HTTP status; error is the machine-readable code.
// All error handlers across services use this shape to produce a consistent response.
export class AppError extends Error {
  constructor(
    public readonly statusCode: number,
    public readonly error: string,
    message: string,
    public readonly details?: Array<{ field: string; issue: string }>,
  ) {
    super(message);
    this.name = this.constructor.name;
    // Required to restore the prototype chain after TypeScript compiles `extends Error`
    Object.setPrototypeOf(this, new.target.prototype);
  }
}

export class BadRequestError extends AppError {
  constructor(message: string, details?: Array<{ field: string; issue: string }>) {
    super(400, 'BAD_REQUEST', message, details);
  }
}

export class UnauthorizedError extends AppError {
  constructor(message = 'Unauthorized') {
    super(401, 'UNAUTHORIZED', message);
  }
}

export class ForbiddenError extends AppError {
  constructor(message = 'Forbidden') {
    super(403, 'FORBIDDEN', message);
  }
}

export class NotFoundError extends AppError {
  constructor(message: string) {
    super(404, 'NOT_FOUND', message);
  }
}

export class ConflictError extends AppError {
  constructor(message: string) {
    super(409, 'CONFLICT', message);
  }
}

export class ServiceUnavailableError extends AppError {
  constructor(message: string) {
    super(503, 'SERVICE_UNAVAILABLE', message);
  }
}
