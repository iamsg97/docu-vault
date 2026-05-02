# syntax=docker/dockerfile:1
# Multi-stage build — final image contains only compiled JS + production node_modules.
# Built image is pushed to ECR and deployed on ECS (EC2 launch type).

FROM node:20-alpine AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable

# ── deps: install all workspace dependencies (layer-cached until package.json changes) ──
FROM base AS deps
WORKDIR /app

# Copy only manifests first so this layer is re-used when only source changes
COPY package.json pnpm-workspace.yaml ./
COPY packages/eslint-config/package.json  ./packages/eslint-config/
COPY packages/shared-types/package.json   ./packages/shared-types/
COPY packages/shared-utils/package.json   ./packages/shared-utils/
COPY apps/bff/package.json                ./apps/bff/

RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
    pnpm install --frozen-lockfile

# ── builder: compile TypeScript ──────────────────────────────────────────────
FROM base AS builder
WORKDIR /app

# Restore installed node_modules from deps stage
COPY --from=deps /app/node_modules                        ./node_modules
COPY --from=deps /app/packages/shared-types/node_modules  ./packages/shared-types/node_modules
COPY --from=deps /app/packages/shared-utils/node_modules  ./packages/shared-utils/node_modules
COPY --from=deps /app/apps/bff/node_modules               ./apps/bff/node_modules

# Copy source trees
COPY tsconfig.json turbo.json ./
COPY packages/eslint-config  ./packages/eslint-config
COPY packages/shared-types   ./packages/shared-types
COPY packages/shared-utils   ./packages/shared-utils
COPY apps/bff                ./apps/bff

# Build dependency packages first, then the BFF
RUN pnpm --filter @docuvault/shared-types build \
 && pnpm --filter @docuvault/shared-utils build \
 && pnpm --filter bff build

# ── runner: minimal production image ─────────────────────────────────────────
FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable

# Non-root user — principle of least privilege
RUN addgroup --system --gid 1001 nodejs \
 && adduser  --system --uid 1001 bff

# Install production deps only
COPY --chown=bff:nodejs package.json pnpm-workspace.yaml ./
COPY --chown=bff:nodejs packages/eslint-config/package.json  ./packages/eslint-config/
COPY --chown=bff:nodejs packages/shared-types/package.json   ./packages/shared-types/
COPY --chown=bff:nodejs packages/shared-utils/package.json   ./packages/shared-utils/
COPY --chown=bff:nodejs apps/bff/package.json                ./apps/bff/

RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
    pnpm install --frozen-lockfile --prod

# Copy compiled output from builder
COPY --from=builder --chown=bff:nodejs /app/packages/shared-types/dist  ./packages/shared-types/dist
COPY --from=builder --chown=bff:nodejs /app/packages/shared-utils/dist  ./packages/shared-utils/dist
COPY --from=builder --chown=bff:nodejs /app/apps/bff/dist               ./apps/bff/dist

USER bff
EXPOSE 3000

# ECS health check — ALB will also hit /health on port 3000
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
  CMD wget -qO- http://localhost:3000/health > /dev/null || exit 1

CMD ["node", "apps/bff/dist/main.js"]
