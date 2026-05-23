# DocuVault — Accumulated Project Learnings

> **How this works:** This file is imported into `CLAUDE.md` via the `@docs/learnings/SUMMARY.md` directive and is therefore loaded into context at the start of every Claude session. It gives Claude accumulated knowledge from prior development work so it doesn't repeat solved problems or re-make settled decisions.
>
> **Maintained by:** Running `/learn` after any session with significant work, or `/feature-complete <name>` when a full feature is done. Each entry should be one line — full detail lives in the linked files.

---

## Quick Reference: Settled Architecture Decisions

These decisions affect all implementation work and must not be re-litigated without explicit user instruction:

| Decision | Choice | Constraint |
| -------- | ------ | ---------- |
| Container orchestration | ECS EC2 launch type | EKS = $73/month control plane cost |
| Vector search | pgvector in PostgreSQL | Same DB, no extra service, $0 cost |
| File delivery | S3 presigned URLs, never stream through backend | Bandwidth + server load |
| List pagination | Cursor-based always | Offset is O(n) at high pages |
| SQS batch processing | `Promise.allSettled`, never `Promise.all` | One failure must not block others |
| Frontend API access | BFF only, never direct service calls | Frontend must not know service topology |
| Processing reliability | SQS + DLQ on every queue, no exceptions | Direct invocation loses failed messages |
| AWS region | `ap-south-1` | User's configured region |

---

## Learnings Index

> New entries are prepended below by `/learn` and `/feature-complete`. Newest section first.

- [AWS Terraform Infrastructure](sessions/2026-05-23-aws-terraform-infrastructure.md) — 14-module IaC for ECS, RDS, DynamoDB, S3, SQS, SNS, Cognito, CloudFront across dev/preprod/prod

---

## How to Navigate Full Docs

- **Feature docs:** `docs/features/` — one file per completed feature, with architecture diagrams, endpoints, and rollback plans
- **Functional learnings:** `docs/learnings/functional/` — business logic, user flows, domain rules
- **Technical learnings:** `docs/learnings/technical/` — implementation patterns, AWS config, debugging tips
- **Design learnings:** `docs/learnings/design/` — architectural trade-offs, pattern rationale, evolution paths
- **ADRs:** `docs/adr/` — formal Architecture Decision Records for major choices
