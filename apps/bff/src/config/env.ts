import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().default(3000),
  LOG_LEVEL: z
    .enum(['trace', 'debug', 'info', 'warn', 'error', 'fatal', 'silent'])
    .default('info'),
  AUTH_SERVICE_URL: z.string().url(),
  DOCUMENT_SERVICE_URL: z.string().url(),
  PROCESSING_SERVICE_URL: z.string().url(),
  SEARCH_SERVICE_URL: z.string().url(),
  NOTIFICATION_SERVICE_URL: z.string().url(),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  // console.error is intentional here — the structured logger is not yet initialised
  // eslint-disable-next-line no-console
  console.error(
    'Invalid or missing environment variables:\n',
    JSON.stringify(parsed.error.flatten().fieldErrors, null, 2),
  );
  process.exit(1);
}

export const env = parsed.data;
export type Env = typeof env;
