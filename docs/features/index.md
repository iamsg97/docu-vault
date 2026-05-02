# DocuVault — Feature Documentation Index

> Auto-updated by `/feature-complete`. Each row links to comprehensive documentation including architecture flow, API changes, DB changes, and all three learning documents.

---

## Completed Features

| Date | Feature | Services Involved | Doc |
|------|---------|------------------|-----|
| — | *(none yet)* | — | — |

---

## Implementation Roadmap

Features will be built roughly in this order. Update the table above as each one is completed.

### Phase 1 — Foundation
- [ ] Turborepo monorepo scaffold (`turbo.json`, `pnpm-workspace.yaml`, root `package.json`)
- [ ] Shared packages: `shared-types`, `shared-utils`, `db-schemas`, `eslint-config`
- [ ] Docker Compose local infrastructure (Postgres/pgvector, DynamoDB Local, LocalStack, Redis)
- [ ] LocalStack bootstrap script (`scripts/setup-localstack.sh`)
- [ ] Prisma schema + initial migration

### Phase 2 — Authentication
- [ ] `auth-service`: signup, login, JWT issuance, Cognito integration
- [ ] `auth-service`: refresh token rotation, logout, `/auth/me`
- [ ] `web`: login and signup pages with React Query + Zustand auth store
- [ ] `bff`: auth middleware, token forwarding to services

### Phase 3 — Document Management
- [ ] `document-service`: create document record + return S3 presigned upload URL
- [ ] `document-service`: list (cursor pagination), get, update metadata, soft delete
- [ ] `document-service`: share document with another user (`/documents/:id/share`)
- [ ] `web`: upload page with drag-and-drop, direct S3 upload via presigned URL
- [ ] `web`: document list with cursor-based infinite scroll

### Phase 4 — Processing Pipeline
- [ ] `lambdas/ocr-trigger`: S3 `PutObject` event → SQS `processing-queue` message
- [ ] `processing-service`: SQS consumer, Textract OCR, document classification
- [ ] `processing-service`: embedding generation, pgvector storage, status updates
- [ ] `processing-service`: DLQ + CloudWatch alarm, retry endpoint
- [ ] `web`: real-time processing status (polling or WebSocket)

### Phase 5 — Search
- [ ] `search-service`: full-text search with PostgreSQL `tsvector`
- [ ] `search-service`: semantic search with pgvector cosine similarity
- [ ] `search-service`: Reciprocal Rank Fusion (RRF) hybrid ranking
- [ ] `search-service`: autocomplete suggestions endpoint
- [ ] `web`: search page with hybrid results and snippets

### Phase 6 — Notifications
- [ ] `notification-service`: SNS → SQS fan-out consumer
- [ ] `notification-service`: in-app notification storage (DynamoDB + TTL)
- [ ] `notification-service`: SES email notifications (optional)
- [ ] `web`: notification bell with unread count and mark-as-read

### Phase 7 — Infrastructure
- [ ] Terraform modules: VPC, ECS, RDS, DynamoDB, S3, ALB, SQS, SNS
- [ ] Terraform modules: CloudFront, Route 53, API Gateway, Lambda
- [ ] GitHub Actions CI/CD: lint → test → build → ECR push → ECS deploy
- [ ] CloudWatch dashboards and alarms

### Phase 8 — Cross-cutting
- [ ] `lambdas/thumbnail-generator`: document preview generation
- [ ] `lambdas/scheduled-cleanup`: expired DynamoDB entry cleanup cron
- [ ] Rate limiting at BFF (Redis sliding window)
- [ ] Audit log writes from all services
- [ ] OpenAPI spec (`docs/api-spec.yaml`) generated from NestJS decorators
