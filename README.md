# DocuVault

> AI-powered document management & verification platform built on AWS microservices.

DocuVault lets users upload documents (PDFs, images, invoices), automatically extracts text via OCR, classifies document types, enables full-text and semantic AI search, and delivers real-time notifications — all running on AWS.

---

## Architecture

**Turborepo monorepo** — microservices, shared packages, Lambda functions, Terraform IaC, and a Next.js frontend in one repo.

```
docuvault/
├── apps/
│   ├── web/                  # Next.js 14 frontend (App Router) — port 4000
│   ├── bff/                  # Backend for Frontend (Express) — port 3000
│   ├── auth-service/         # NestJS — Cognito, JWT — port 3001
│   ├── document-service/     # NestJS — CRUD, S3 presigned URLs — port 3002
│   ├── processing-service/   # NestJS — OCR, Textract, classification — port 3003
│   ├── search-service/       # NestJS — full-text + semantic search — port 3004
│   └── notification-service/ # NestJS — SQS consumer, notifications — port 3005
├── packages/
│   ├── shared-types/         # TypeScript interfaces, DTOs, enums
│   ├── shared-utils/         # Logger, error classes, helpers
│   ├── db-schemas/           # Prisma schema + migrations
│   └── eslint-config/        # Shared ESLint + Prettier config
├── lambdas/
│   ├── ocr-trigger/          # S3 upload event → SQS
│   ├── thumbnail-generator/  # Document preview generation
│   └── scheduled-cleanup/    # Cron: expire DynamoDB entries
└── infra/                    # Terraform IaC (all AWS resources)
```

### AWS Services

| Service | Purpose |
|---------|---------|
| ECS (EC2 launch type) | Container orchestration for all microservices |
| RDS PostgreSQL + pgvector | Relational data + semantic vector search |
| DynamoDB | Processing job state + notification log |
| S3 + CloudFront | Document storage + CDN delivery |
| SQS + SNS | Async processing pipeline + event fan-out |
| Textract | OCR and key-value extraction |
| Cognito | Authentication + OAuth 2.0 |
| Lambda | Event-driven functions (OCR trigger, thumbnails, cleanup) |
| API Gateway + ALB | Traffic routing |
| Route 53 | DNS |
| ECR | Container image registry |
| CloudWatch | Logs, alarms, monitoring |

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Next.js 14 (App Router), Tailwind CSS |
| State Management | Zustand + React Query (TanStack) |
| BFF | Express.js + TypeScript |
| Backend Services | NestJS + TypeScript |
| ORM | Prisma |
| Database | PostgreSQL 15 (RDS) + pgvector |
| NoSQL | DynamoDB |
| Cache | Redis (ElastiCache / Redis Cloud free tier) |
| IaC | Terraform |
| CI/CD | GitHub Actions → ECR → ECS |
| Package Manager | pnpm |
| Monorepo | Turborepo |
| Testing | Jest, Vitest, Supertest |

---

## Branch Strategy

| Branch | Purpose |
|--------|---------|
| `develop` | Active development — all feature branches merge here |
| `preprod` | Validation and staging — merged from `develop` before production |
| `main` | Production deployments only — merged from `preprod` after validation |

```
feature/* → develop → preprod → main
```

---

## Getting Started

### Prerequisites

- Node.js >= 20
- pnpm >= 9
- Docker CLI
- AWS CLI v2 (configured: `aws configure`)
- Terraform >= 1.5

### Install

```bash
git clone <repo-url>
cd docuvault
pnpm install
```

### Bootstrap AWS Infrastructure

```bash
cd infra/environments/dev
terraform init
terraform apply
```

This provisions RDS, DynamoDB, S3, SQS, SNS, ECR repos, and all supporting resources under the AWS free tier.

### Run Prisma Migrations

```bash
# DATABASE_URL must point to the RDS endpoint from Terraform output
pnpm --filter db-schemas prisma migrate dev
pnpm --filter db-schemas prisma generate
```

### Configure Environment Variables

Each service has a `.env.example`. Copy and fill in AWS resource values from Terraform output:

```bash
cp apps/auth-service/.env.example apps/auth-service/.env
# repeat for each service
```

### Start All Services

```bash
pnpm dev
```

Services start on ports 3000–3005 (backend) and 4000 (frontend). All data services (RDS, DynamoDB, S3, SQS, SNS) are remote on AWS.

---

## Commands

### Monorepo (root)

```bash
pnpm dev          # Start all services
pnpm build        # Build all packages and apps
pnpm lint         # Lint everything
pnpm test         # Run all tests
pnpm test:e2e     # Run end-to-end tests
pnpm format       # Prettier format all files
pnpm clean        # Remove node_modules and dist
```

### Individual Service

```bash
pnpm --filter web dev
pnpm --filter auth-service dev
pnpm --filter document-service test
pnpm --filter shared-types build
```

### Docker / ECR

```bash
# Authenticate with ECR
aws ecr get-login-password --region ap-south-1 | \
  docker login --username AWS --password-stdin \
  $(aws sts get-caller-identity --query Account --output text).dkr.ecr.ap-south-1.amazonaws.com

# Build and push a service
SERVICE=auth-service
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
REPO=$ACCOUNT.dkr.ecr.ap-south-1.amazonaws.com/docuvault-$SERVICE

docker build -t $REPO:latest apps/$SERVICE/
docker push $REPO:latest
```

### Terraform

```bash
cd infra/environments/dev
terraform init
terraform plan
terraform apply
terraform destroy   # Tear down to avoid charges
```

---

## Document Upload Pipeline

```
User requests presigned URL
  → BFF → document-service → S3 presigned URL returned to frontend
  → Frontend uploads file directly to S3
  → S3 PutObject event → Lambda (ocr-trigger)
  → Lambda publishes to SQS (processing-queue)
  → processing-service polls SQS:
      1. Textract OCR
      2. Document classification
      3. Key-value extraction
      4. Store extracted text in RDS
      5. Generate embeddings → pgvector
      6. Update document status in RDS
      7. Update job state in DynamoDB
      8. Publish SNS event (processing.complete)
  → notification-service receives via SQS
  → Stores in-app notification in DynamoDB
```

## Search Flow

```
User query → BFF → search-service
  → Full-text search (PostgreSQL tsvector)
  → Semantic search (pgvector cosine similarity)
  → Reciprocal Rank Fusion
  → Ranked results with snippets
```

---

## Deployment Pipeline

```
Push to main
  → GitHub Actions: lint + test (parallel, via Turborepo)
  → Build Docker images
  → Push to ECR
  → Update ECS task definitions
  → ECS rolling deployment
  → Health check passes → done
  → Health check fails → auto-rollback
```

---

## Cost Notes

All infrastructure targets the **AWS free tier ($0/month)**. Key limits:

| Service | Free Tier |
|---------|-----------|
| RDS `db.t3.micro` | 750 hrs/month |
| DynamoDB | 25 GB + 25 RCU/WCU |
| S3 | 5 GB, 20K GET, 2K PUT |
| SQS | 1M requests/month |
| Lambda | 1M requests/month |
| Cognito | 50K MAU |

> Stop the RDS instance when not actively developing. Run `terraform destroy` for extended breaks.

---

## License

[MIT](LICENSE)
