---
date: YYYY-MM-DD
feature: feature-name
status: complete | in-progress | deprecated
services: [web, bff, auth-service, document-service, processing-service, search-service, notification-service]
lambdas: [ocr-trigger, thumbnail-generator, scheduled-cleanup]
---

# Feature: [Feature Name]

## Overview

<!-- 2–3 sentences for a non-technical reader. What does this feature do and why does it exist? -->

## User Story

> As a [user role], I want to [action], so that [outcome].

## Architecture Flow

<!-- Trace the full request/event path. Be specific about services, queues, and tables. -->

```
[Trigger] → [Component A] → [Component B]
                              ↓
                         [DB/Queue/AWS]
                              ↓
                         [Component C] → [Response/Event]
```

## Services and Their Roles

| Service / Component | Role in this feature |
|--------------------|----------------------|
| `web` | |
| `bff` | |
| `document-service` | |
| SQS `queue-name` | |
| DynamoDB `TableName` | |

## API Endpoints

<!-- New or modified endpoints. Include auth requirement and brief description. -->

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `POST` | `/api/v1/...` | Bearer JWT | |

## Database Changes

<!-- New tables, columns, indexes, or DynamoDB tables created for this feature. -->

**PostgreSQL (Prisma):**
- New model / new field: description

**DynamoDB:**
- Table: `TableName` — access pattern: PK = `X#<id>`, SK = `Y#<timestamp>`

## Event Flow

<!-- SQS messages, SNS topics, EventBridge rules involved. Include message schema if non-trivial. -->

1. [Service A] publishes `{ type: "...", documentId: "..." }` to SNS topic `processing-events`
2. [Service B] receives via SQS subscription and processes

## Key Implementation Notes

<!-- Technical decisions specific to this feature that aren't captured elsewhere. -->

-

## Testing

**Unit tests:**
- `apps/[service]/src/[module]/[service].spec.ts` — covers [scenarios]

**Integration tests:**
- `apps/[service]/src/[module]/[controller].e2e-spec.ts`

**Manual testing steps:**
1. Start local infra: `docker compose -f docker/docker-compose.yml up -d`
2. [Step-by-step]

## Rollback Plan

<!-- How to revert if this feature causes production issues. -->

1. [Step]
2. [Step]

## Learnings Generated

<!-- Links to the three learning documents created alongside this feature. -->

- [Functional](../learnings/functional/YYYY-MM-DD-feature-name.md) — business logic and user flow
- [Technical](../learnings/technical/YYYY-MM-DD-feature-name.md) — implementation patterns and decisions
- [Design](../learnings/design/YYYY-MM-DD-feature-name.md) — architecture rationale
