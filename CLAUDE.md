# CLAUDE.md — DocuVault

> AI-powered document management & verification platform built on AWS microservices.

---

## Project Overview

DocuVault is an enterprise document management platform where users upload documents (PDFs, images, invoices), the system automatically extracts text via OCR, classifies document types, enables full-text + semantic AI search, and notifies users — all running on AWS.

**This is a Turborepo monorepo** containing all microservices, shared packages, Lambda functions, infrastructure-as-code, and the frontend.

### Target AWS Services

ECS (EC2 launch type), Lambda, S3, CloudFront, Route 53, ALB, API Gateway, RDS (PostgreSQL + pgvector), DynamoDB, SQS, SNS, EventBridge, Textract, Cognito, ECR, CloudWatch

### Budget Constraint

**Free tier only ($0/month).** All architecture decisions must respect AWS free tier limits. Development runs against real AWS services using free tier resources — no local emulators.

---

## Repository Structure

```
docuvault/
├── turbo.json                    # Turborepo pipeline config
├── package.json                  # Root workspace config (pnpm)
├── pnpm-workspace.yaml
├── .github/workflows/            # CI/CD — GitHub Actions → ECR → ECS
├── CLAUDE.md                     # This file
│
├── infra/                        # Terraform IaC (all AWS resources)
│   ├── modules/
│   │   ├── vpc/
│   │   ├── ecs/
│   │   ├── rds/
│   │   ├── dynamodb/
│   │   ├── s3/
│   │   ├── lambda/
│   │   ├── cloudfront/
│   │   ├── route53/
│   │   ├── alb/
│   │   ├── sqs/
│   │   ├── sns/
│   │   └── api-gateway/
│   ├── environments/
│   │   ├── dev/
│   │   └── prod/
│   └── main.tf
│
├── packages/                     # Shared internal packages
│   ├── shared-types/             # TypeScript interfaces, DTOs, enums
│   ├── shared-utils/             # Logger, error classes, helpers
│   ├── db-schemas/               # Prisma schema + migrations
│   └── eslint-config/            # Shared ESLint + Prettier config
│
├── apps/                         # Deployable microservices
│   ├── web/                      # Next.js 14 frontend (App Router)
│   ├── bff/                      # Backend for Frontend (Express + TS)
│   ├── auth-service/             # NestJS — Cognito, JWT, OAuth 2.0
│   ├── document-service/         # NestJS — CRUD, S3 presigned URLs
│   ├── processing-service/       # NestJS — OCR pipeline, Textract, classification
│   ├── search-service/           # NestJS — full-text (tsvector) + semantic (pgvector)
│   └── notification-service/     # NestJS — SQS consumer, in-app + email notifications
│
├── lambdas/                      # AWS Lambda functions
│   ├── ocr-trigger/              # S3 upload event → SQS message
│   ├── thumbnail-generator/      # Generate document previews
│   └── scheduled-cleanup/        # Cron: clean expired DynamoDB entries
│
└── docs/
    ├── architecture.md           # Architecture diagrams + decisions
    ├── api-spec.yaml             # OpenAPI 3.0 spec
    ├── eks-migration.md          # ECS → EKS migration guide
    └── adr/                      # Architecture Decision Records
```

---

## Tech Stack

| Layer              | Technology                        |
|--------------------|-----------------------------------|
| Frontend           | Next.js 14 (App Router), Tailwind CSS |
| State Management   | Zustand + React Query (TanStack)  |
| BFF                | Express.js + TypeScript           |
| Backend Services   | NestJS + TypeScript               |
| ORM                | Prisma                            |
| Relational DB      | PostgreSQL 15 (RDS) + pgvector    |
| NoSQL DB           | DynamoDB                          |
| Cache              | Redis (ElastiCache or local)      |
| File Storage       | AWS S3                            |
| Auth               | AWS Cognito + custom JWT guards   |
| OCR                | AWS Textract (fallback: Tesseract.js) |
| Message Queue      | AWS SQS                           |
| Pub/Sub            | AWS SNS                           |
| Event Routing      | AWS EventBridge                   |
| Serverless         | AWS Lambda (Node.js 20 runtime)   |
| Container Orchestration | AWS ECS (EC2 launch type)    |
| CDN                | AWS CloudFront                    |
| DNS                | AWS Route 53                      |
| Load Balancer      | AWS ALB                           |
| IaC                | Terraform                         |
| CI/CD              | GitHub Actions → ECR → ECS        |
| Package Manager    | pnpm                              |
| Monorepo Tool      | Turborepo                         |
| Testing            | Jest, Vitest, Supertest           |
| Linting            | ESLint + Prettier (shared config) |
| API Docs           | Swagger / OpenAPI 3.0 (NestJS)    |
| Container Registry | AWS ECR (Elastic Container Registry) |

---

## Commands

### Root Level (Turborepo)

```bash
pnpm install                        # Install all dependencies
pnpm dev                            # Start all services in dev mode
pnpm build                          # Build all packages and apps
pnpm lint                           # Lint everything
pnpm test                           # Run all tests
pnpm test:e2e                       # Run e2e tests
pnpm format                         # Prettier format all files
pnpm clean                          # Remove all node_modules and dist
```

### Individual Service

```bash
pnpm --filter web dev               # Start frontend only
pnpm --filter auth-service dev      # Start auth service only
pnpm --filter document-service test # Test document service only
pnpm --filter shared-types build    # Build shared types package
```

### ECR (Container Registry)

```bash
# Authenticate Docker CLI with ECR (run before any build/push)
aws ecr get-login-password --region ap-south-1 | \
  docker login --username AWS --password-stdin \
  $(aws sts get-caller-identity --query Account --output text).dkr.ecr.ap-south-1.amazonaws.com

# Create a repository for a service (one-time, or via Terraform)
aws ecr create-repository --repository-name docuvault-auth-service --region ap-south-1

# Build and push a service image
SERVICE=auth-service
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
REPO=$ACCOUNT.dkr.ecr.ap-south-1.amazonaws.com/docuvault-$SERVICE

docker build -t $REPO:latest apps/$SERVICE/
docker push $REPO:latest

# List images in a repository
aws ecr list-images --repository-name docuvault-$SERVICE --region ap-south-1
```

### Terraform

```bash
cd infra/environments/dev
terraform init
terraform plan
terraform apply
terraform destroy                   # Tear down to avoid charges
```

### Lambda

```bash
cd lambdas/ocr-trigger
npm run build                       # Bundle with esbuild
npm run deploy                      # Deploy via Terraform or AWS CLI
```

---

## Microservice Details

### auth-service (Port 3001)

- **Framework:** NestJS
- **DB:** PostgreSQL (users table via Prisma)
- **Auth Provider:** AWS Cognito
- **Endpoints:**
  - `POST /auth/signup` — register user (Cognito + local DB)
  - `POST /auth/login` — authenticate, return JWT tokens
  - `POST /auth/refresh` — rotate refresh token
  - `GET /auth/me` — get current user profile
  - `POST /auth/logout` — invalidate session
- **Key patterns:** JWT Guard, Cognito integration, refresh token rotation, RBAC

### document-service (Port 3002)

- **Framework:** NestJS
- **DB:** PostgreSQL (documents, document_shares tables via Prisma)
- **Storage:** AWS S3 (presigned URLs for upload/download)
- **Endpoints:**
  - `POST /documents` — create document record + return presigned upload URL
  - `GET /documents` — list user's documents (paginated, cursor-based)
  - `GET /documents/:id` — get document metadata + presigned download URL
  - `PUT /documents/:id` — update metadata (title, tags)
  - `DELETE /documents/:id` — soft delete
  - `POST /documents/:id/share` — share with another user
  - `GET /documents/:id/status` — processing status
- **Key patterns:** Presigned S3 URLs (no files through backend), cursor pagination, soft delete, permission model

### processing-service (Port 3003)

- **Framework:** NestJS
- **DB:** DynamoDB (processing job state)
- **Queue:** SQS consumer (polling)
- **Endpoints:**
  - `GET /processing/:documentId/status` — job status
  - `POST /processing/:documentId/retry` — retry failed job
- **Key patterns:** SQS long polling, Textract integration, document classification, DLQ with CloudWatch alarm, idempotent processing

### search-service (Port 3004)

- **Framework:** NestJS
- **DB:** PostgreSQL (pgvector for embeddings, tsvector for full-text)
- **Endpoints:**
  - `GET /search?q=<query>` — hybrid search (full-text + semantic)
  - `GET /search/suggest?q=<prefix>` — autocomplete suggestions
- **Key patterns:** pgvector cosine similarity, tsvector full-text, hybrid ranking (RRF), chunked embeddings

### notification-service (Port 3005)

- **Framework:** NestJS
- **DB:** DynamoDB (notification log with TTL)
- **Queue:** SQS consumer (subscribed via SNS)
- **Endpoints:**
  - `GET /notifications` — list user notifications
  - `PATCH /notifications/:id/read` — mark as read
- **Key patterns:** SNS → SQS fan-out, in-app notifications, SES email (optional)

### bff (Port 3000)

- **Framework:** Express.js + TypeScript
- **Purpose:** Aggregates calls to backend services for the frontend
- **Routes mirror frontend needs**, not backend service boundaries
- **Key patterns:** Request aggregation, response shaping, auth token forwarding, circuit breaker (if downstream service is down)

### web (Port 4000)

- **Framework:** Next.js 14 (App Router)
- **Styling:** Tailwind CSS
- **State:** Zustand (client state) + React Query (server state)
- **Pages:**
  - `/` — landing / dashboard
  - `/login`, `/signup` — auth
  - `/documents` — document list with search
  - `/documents/[id]` — document viewer + metadata
  - `/upload` — upload page with drag-and-drop
  - `/search` — search results page
  - `/settings` — user settings
- **Key patterns:** SSR where needed, client-side upload to S3 via presigned URL, optimistic UI updates

---

## Database Schemas

### PostgreSQL (RDS) — via Prisma

```prisma
model User {
  id            String    @id @default(uuid())
  cognitoId     String    @unique
  email         String    @unique
  name          String
  avatarUrl     String?
  role          Role      @default(USER)
  documents     Document[]
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt
}

model Document {
  id              String    @id @default(uuid())
  userId          String
  user            User      @relation(fields: [userId], references: [id])
  title           String
  fileKey         String    // S3 object key
  fileType        String    // pdf, png, jpg, docx
  fileSize        Int       // bytes
  status          DocStatus @default(UPLOADED)
  classification  String?   // invoice, receipt, id, contract
  extractedText   String?   // full OCR text
  metadata        Json?     // key-value pairs from Textract
  isDeleted       Boolean   @default(false)
  shares          DocumentShare[]
  embeddings      DocumentEmbedding[]
  createdAt       DateTime  @default(now())
  updatedAt       DateTime  @updatedAt

  @@index([userId, createdAt])
  @@index([status])
}

model DocumentShare {
  id              String     @id @default(uuid())
  documentId      String
  document        Document   @relation(fields: [documentId], references: [id])
  sharedWithEmail String
  sharedWithId    String?
  permission      Permission @default(VIEW)
  createdAt       DateTime   @default(now())

  @@unique([documentId, sharedWithEmail])
}

model DocumentEmbedding {
  id          String   @id @default(uuid())
  documentId  String
  document    Document @relation(fields: [documentId], references: [id])
  chunkText   String
  chunkIndex  Int
  embedding   Unsupported("vector(1536)")
  createdAt   DateTime @default(now())

  @@index([documentId])
}

model AuditLog {
  id           String   @id @default(uuid())
  userId       String
  action       String   // UPLOAD, DELETE, SHARE, VIEW, SEARCH
  resourceType String   // DOCUMENT, USER
  resourceId   String
  metadata     Json?
  createdAt    DateTime @default(now())

  @@index([userId, createdAt])
}

enum Role { USER ADMIN }
enum DocStatus { UPLOADED PROCESSING COMPLETED FAILED }
enum Permission { VIEW EDIT }
```

### DynamoDB Tables

```
Table: ProcessingJobs
  PK: DOC#<documentId>
  SK: JOB#<timestamp>
  Attributes: status, progress (0-100), error, retryCount, startedAt, completedAt
  TTL: expiresAt (auto-delete after 30 days)

Table: NotificationLog
  PK: USER#<userId>
  SK: NOTIF#<timestamp>
  Attributes: type (PROCESSING_COMPLETE | DOCUMENT_SHARED | SYSTEM), message, read (bool), documentId
  TTL: expiresAt (auto-delete after 90 days)

Table: UserSessions (if not using Cognito sessions)
  PK: SESSION#<sessionId>
  Attributes: userId, createdAt
  TTL: expiresAt
```

---

## Event Flows

### Document Upload Pipeline

```
User → Frontend (presigned URL request)
  → BFF → document-service → S3 presigned URL → Frontend
  → Frontend uploads directly to S3
  → S3 PutObject event → Lambda (ocr-trigger)
  → Lambda → SQS (processing-queue)
  → processing-service polls SQS:
      1. Call Textract (OCR)
      2. Classify document type
      3. Extract key-value pairs
      4. Store extracted text → RDS
      5. Generate embedding → store in pgvector
      6. Update document status → RDS
      7. Update processing job → DynamoDB
      8. Publish SNS event ("processing.complete")
  → notification-service receives via SQS
  → Stores in-app notification → DynamoDB
```

### Search Flow

```
User types query → BFF → search-service
  → Full-text search (PostgreSQL tsvector)
  → Semantic search (pgvector cosine similarity)
  → Reciprocal Rank Fusion to merge results
  → Return ranked results with snippets
```

---

## Coding Conventions

### General

- **Language:** TypeScript everywhere (except Terraform = HCL, Prisma = PSL)
- **Style:** ESLint + Prettier via shared config in `packages/eslint-config`
- **Imports:** Use path aliases (`@docuvault/shared-types`, `@docuvault/shared-utils`)
- **No `any`:** Use `unknown` and narrow. Exceptions only with `// eslint-disable-next-line` + justification comment
- **Errors:** Always use custom error classes from `packages/shared-utils/errors.ts`
- **Logging:** Always use structured logger from `packages/shared-utils/logger.ts` — never `console.log` in service code
- **Environment variables:** Validated at startup using `zod` schemas. Fail fast if missing.

### NestJS Services

- One module per domain (e.g., `documents.module.ts`)
- Controllers handle HTTP only — no business logic
- Services contain business logic
- Use DTOs with `class-validator` for input validation
- Use Guards for auth, Interceptors for logging/transforms
- Use `@Injectable()` for everything — leverage DI
- Repository pattern for database access (Prisma injected into repositories)

### Express BFF

- Route files organized by frontend page/feature
- Middleware: auth token forwarding, request ID, error handler
- Use `axios` with circuit breaker (e.g., `opossum`) for downstream calls
- Response shaping happens here — backend services return raw data, BFF formats for frontend

### Next.js Frontend

- App Router (not Pages Router)
- Server Components by default, `'use client'` only when needed
- API calls go through BFF only — frontend never calls backend services directly
- Zustand stores in `stores/` directory
- React Query hooks in `hooks/` directory
- Components: `components/ui/` (generic), `components/features/` (domain-specific)

### Lambda Functions

- Single responsibility per Lambda
- Bundle with esbuild (smallest package size)
- Handler in `index.ts`, business logic in separate files
- Always set timeout (default 30s) and memory (default 128MB) explicitly
- Log to stdout (CloudWatch picks it up automatically)

### Terraform

- One module per AWS service in `infra/modules/`
- Environment-specific vars in `infra/environments/<env>/terraform.tfvars`
- Use `locals` for computed values, `variables` for inputs
- Tag every resource: `Project = "docuvault"`, `Environment = "dev"`, `ManagedBy = "terraform"`
- Remote state in S3 + DynamoDB lock table

### Testing

- **Unit tests:** Jest (NestJS services), Vitest (frontend)
- **Integration tests:** Supertest for API endpoints
- **Mocking AWS:** `aws-sdk-client-mock` for SQS/SNS/S3/DynamoDB
- **Integration tests against AWS:** Use a dedicated `test` AWS account or isolated prefixed resources (e.g., `test-processing-queue`) — `aws-sdk-client-mock` covers the majority of cases
- **Naming:** `*.spec.ts` for unit tests, `*.e2e-spec.ts` for integration tests
- **Coverage target:** 80%+ for services, 60%+ for frontend

### Git Conventions

- **Branch naming:** `feat/<feature>`, `fix/<bug>`, `chore/<task>`, `infra/<aws-resource>`
- **Commit messages:** Conventional Commits — `feat(document-service): add presigned URL generation`
- **PR template:** What changed, why, how to test, screenshots (if UI)
- **No direct push to `main`** — always PR with at least self-review

---

## Environment Variables

Each service has a `.env.example` file. Copy to `.env` for local dev.

### Common (all services)

```
NODE_ENV=development
LOG_LEVEL=debug
AWS_REGION=ap-south-1
AWS_ACCESS_KEY_ID=              # From `aws configure` or IAM role — never commit real values
AWS_SECRET_ACCESS_KEY=          # From `aws configure` or IAM role — never commit real values
```

### auth-service

```
PORT=3001
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/docuvault
COGNITO_USER_POOL_ID=
COGNITO_CLIENT_ID=
JWT_SECRET=local-dev-secret
JWT_EXPIRY=15m
REFRESH_TOKEN_EXPIRY=7d
```

### document-service

```
PORT=3002
DATABASE_URL=postgresql://postgres:postgres@<rds-endpoint>:5432/docuvault
S3_BUCKET_NAME=docuvault-documents
PRESIGNED_URL_EXPIRY=3600           # 1 hour
```

### processing-service

```
PORT=3003
SQS_QUEUE_URL=https://sqs.ap-south-1.amazonaws.com/<account-id>/processing-queue
DYNAMODB_TABLE_PROCESSING=ProcessingJobs
SNS_TOPIC_ARN=arn:aws:sns:ap-south-1:<account-id>:processing-events
```

### search-service

```
PORT=3004
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/docuvault
EMBEDDING_MODEL=text-embedding-ada-002   # or local model
EMBEDDING_API_KEY=                        # OpenAI key (optional, for embeddings)
```

### notification-service

```
PORT=3005
SQS_QUEUE_URL=https://sqs.ap-south-1.amazonaws.com/<account-id>/notification-queue
DYNAMODB_TABLE_NOTIFICATIONS=NotificationLog
```

### bff

```
PORT=3000
AUTH_SERVICE_URL=http://localhost:3001
DOCUMENT_SERVICE_URL=http://localhost:3002
PROCESSING_SERVICE_URL=http://localhost:3003
SEARCH_SERVICE_URL=http://localhost:3004
NOTIFICATION_SERVICE_URL=http://localhost:3005
```

### web

```
PORT=4000
NEXT_PUBLIC_BFF_URL=http://localhost:3000
NEXT_PUBLIC_S3_BUCKET_URL=https://docuvault-documents.s3.ap-south-1.amazonaws.com
```

---

## Local Development Setup

### Prerequisites

- Node.js >= 20
- pnpm >= 9
- Docker CLI (for building and pushing images to ECR — no Compose needed)
- AWS CLI v2 (configured with dev IAM credentials: `aws configure`)
- Terraform >= 1.5

### First Time Setup

```bash
# 1. Clone and install
git clone <repo-url>
cd docuvault
pnpm install

# 2. Bootstrap AWS dev resources via Terraform
cd infra/environments/dev
terraform init
terraform apply   # Provisions RDS, DynamoDB, S3, SQS, SNS, ElastiCache, ECR repos

# 3. Run Prisma migrations against the provisioned RDS instance
#    (DATABASE_URL must point to the RDS endpoint from Terraform output)
pnpm --filter db-schemas prisma migrate dev
pnpm --filter db-schemas prisma generate

# 4. Bootstrap remaining AWS resources (SQS queues, SNS topics, S3 bucket, DynamoDB tables)
./scripts/setup-aws-dev.sh
# Uses AWS CLI — creates queues/topics/tables if not already created by Terraform

# 5. Copy and populate environment files
cp apps/auth-service/.env.example apps/auth-service/.env
# ... repeat for each service, filling in real AWS resource ARNs/URLs from Terraform output

# 6. Start all services
pnpm dev
```

### AWS Services Used in Development

All services run on actual AWS — no local emulators. All are covered by the AWS free tier.

| AWS Service | Free Tier | Used For |
|-------------|-----------|----------|
| RDS PostgreSQL (`db.t3.micro`) | 750 hrs/month | User data, documents, embeddings, audit logs |
| DynamoDB | 25 GB + 25 RCU/WCU | ProcessingJobs, NotificationLog, UserSessions |
| S3 | 5 GB storage, 20K GET, 2K PUT | Document file storage + presigned URLs |
| SQS | 1M requests/month | Processing queue, notification queue, DLQs |
| SNS | 1M publishes/month | Processing events fan-out |
| Cognito | 50K MAU | Authentication |
| Lambda | 1M requests/month | ocr-trigger, thumbnail-generator, scheduled-cleanup |
| ECR | 500 MB/month | Container image storage for all services |
| ElastiCache (`cache.t3.micro`) | **No free tier** — use Redis Cloud free tier (30 MB) for rate limiting |

> **Cost note:** Stop the RDS instance when not developing to stay within free tier hours.
> Run `terraform destroy` to tear everything down when done for extended periods.

---

## API Design Rules

- **Versioned:** All routes prefixed with `/api/v1/`
- **Consistent error format:**
  ```json
  {
    "statusCode": 400,
    "error": "BAD_REQUEST",
    "message": "Human-readable message",
    "details": [{ "field": "email", "issue": "Invalid format" }]
  }
  ```
- **Pagination:** Cursor-based for lists (`?cursor=<lastId>&limit=20`)
- **Idempotency:** `Idempotency-Key` header for all POST/PUT mutations
- **Auth:** `Authorization: Bearer <jwt>` header on all protected routes
- **Request IDs:** Every request gets `X-Request-Id` header (generated by BFF, forwarded to services)
- **Rate limiting:** Applied at BFF level via Redis sliding window
- **CORS:** Configured at BFF — only allow frontend origin

---

## Deployment Pipeline

```
Push to main
  → GitHub Actions triggers
  → Lint + Test (all services in parallel via Turborepo)
  → Build Docker images
  → Push to ECR
  → Update ECS task definitions
  → ECS rolling deployment
  → Health check passes → done
  → Health check fails → auto-rollback
```

---

## Important Decisions (ADRs)

1. **ECS over EKS** — EKS control plane costs $73/month. ECS EC2 launch type is free tier eligible. Architecture is EKS-ready (containerized, stateless, env-var configured). See `docs/eks-migration.md`.

2. **pgvector over Pinecone/OpenSearch** — Already using PostgreSQL. pgvector keeps vector search in the same DB. Fewer moving parts, lower cost, simpler ops.

3. **BFF over direct frontend-to-service calls** — Frontend should not know about service topology. BFF aggregates, shapes responses, handles auth forwarding, and provides a stable contract for the frontend.

4. **Presigned URLs over streaming through backend** — Files never touch backend servers. Frontend uploads/downloads directly to/from S3. Backend only generates presigned URLs. Saves bandwidth, reduces server load.

5. **SQS over direct Lambda invocation for processing** — SQS provides retry, DLQ, backpressure, and decoupling. Direct Lambda invocation loses failed messages.

6. **Cursor pagination over offset** — Offset is O(n) at high page numbers. Cursor is O(1) always. All list endpoints use cursor-based pagination.

7. **Turborepo + pnpm over Nx or Lerna** — Simpler config, fast caching, works well with both Next.js and NestJS. pnpm for strict dependency management.

---

## Debugging Tips

- **SQS message stuck:** Check visibility timeout vs processing time — inspect via `aws sqs get-queue-attributes --queue-url <url> --attribute-names All`
- **DynamoDB:** Use `aws dynamodb scan --table-name ProcessingJobs` to inspect items; add `--region ap-south-1` if needed
- **Prisma issues:** Run `pnpm --filter db-schemas prisma studio` for a visual DB browser (connects to RDS via `DATABASE_URL`)
- **S3 presigned URL failing:** Ensure the bucket CORS policy allows the frontend origin and the presigned URL has not expired
- **ECR push failing:** Re-run the `aws ecr get-login-password | docker login` command — ECR auth tokens expire after 12 hours
- **ECS task not starting:** Check CloudWatch log group `/ecs/docuvault-<service>` for container startup errors
- **Port conflicts:** Services run locally on 3000–3005, frontend on 4000; all AWS data services are remote
- **Free tier budget check:** `aws ce get-cost-and-usage --time-period Start=YYYY-MM-01,End=YYYY-MM-DD --granularity MONTHLY --metrics BlendedCost`

---

## Do NOT

- Do not use `Fargate` launch type for ECS — not free tier
- Do not use `EKS` — control plane costs $73/month
- Do not use Docker Compose for infrastructure — all services run on AWS (ECS, RDS, DynamoDB, S3, SQS, SNS)
- Do not hardcode AWS account IDs or ARNs — use Terraform outputs and environment variables
- Do not store files in the backend server — always use S3 presigned URLs
- Do not use `console.log` — use the structured logger
- Do not put secrets in `.env` files in git — use `.env.example` with placeholders
- Do not use `offset` pagination — always cursor-based
- Do not call backend services directly from the frontend — always go through BFF
- Do not use `Promise.all` for batch SQS processing — use `Promise.allSettled`
- Do not skip DLQ setup on any SQS queue
- Do not leave RDS running when not developing — stop or `terraform destroy`
- Do not use `WidthType.PERCENTAGE` in any AWS SDK numeric configs — always use explicit values

---

## Accumulated Project Learnings

> The file below is automatically maintained by running `/learn` or `/feature-complete` during Claude Code sessions.
> It gives every new session accumulated knowledge from prior development work — patterns discovered, decisions made, trade-offs understood.
> Full detail is in `docs/learnings/` and `docs/features/`. Keep summaries there lean.

@docs/learnings/SUMMARY.md
