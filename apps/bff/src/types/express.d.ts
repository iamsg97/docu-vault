// Augments Express's Request type to include fields attached by our middleware.
declare namespace Express {
  interface Request {
    requestId: string;
  }
}
