Generate complete documentation for a finished feature named: $ARGUMENTS

Work through these steps in order. Be thorough — these documents are the institutional memory that future Claude sessions will read before touching this code.

---

## Step 1 — Understand what was built

Read the relevant source files for this feature. Trace the full path: HTTP request → controller → service → repository → DB/queue/AWS. Note every non-obvious decision in the code.

---

## Step 2 — Create the feature document

Write a file at `docs/features/YYYY-MM-DD-$ARGUMENTS.md` (substitute today's actual date). Use `docs/features/_template.md` as the structure. Fill every section with real specifics — no placeholders.

---

## Step 3 — Write three learning documents

### 3a. Functional learning
Path: `docs/learnings/functional/YYYY-MM-DD-$ARGUMENTS.md`

Cover:
- The user/business problem this feature solves
- The exact user flow step-by-step
- Business rules and invariants that must always hold
- Edge cases the code handles (and any it intentionally defers)
- Which other services/tables/queues this feature touches and how

### 3b. Technical learning
Path: `docs/learnings/technical/YYYY-MM-DD-$ARGUMENTS.md`

Cover:
- Implementation patterns applied (NestJS DI, SQS polling, presigned URL flow, etc.)
- Every non-obvious decision with the "why" — things that look wrong but are intentional
- AWS service configuration choices that matter (visibility timeout, TTL, index keys, etc.)
- Performance or cost considerations
- How to debug issues in this area (what logs to look for, what state to inspect)
- Key files a developer would open first when working on this feature

### 3c. Design learning
Path: `docs/learnings/design/YYYY-MM-DD-$ARGUMENTS.md`

Cover:
- The architectural pattern this feature follows (e.g., Saga, event-driven, CQRS)
- Alternatives that were considered and why they were rejected
- Known trade-offs of the chosen design (be honest about downsides)
- How this integrates with the broader DocuVault event flow and service topology
- What would need to change if requirements grew (e.g., multi-tenancy, higher throughput)

---

## Step 4 — Update SUMMARY.md

Append to `docs/learnings/SUMMARY.md` under a new dated section heading:

```
### [YYYY-MM-DD] Feature: $ARGUMENTS
- **Functional** [one-line description of what the feature does for the user]. See `docs/learnings/functional/YYYY-MM-DD-$ARGUMENTS.md`
- **Technical** [one-line insight about the most important implementation decision]. See `docs/learnings/technical/YYYY-MM-DD-$ARGUMENTS.md`
- **Design** [one-line description of the architecture pattern used]. See `docs/learnings/design/YYYY-MM-DD-$ARGUMENTS.md`
- **Feature doc**: `docs/features/YYYY-MM-DD-$ARGUMENTS.md`
```

Keep each bullet to a single sentence — SUMMARY.md is loaded into every session and must stay lean.

---

## Step 5 — Update the features index

Add a row to the table in `docs/features/index.md` with today's date, the feature name, status "complete", and the services involved.

---

Write for the developer who will work on this in 6 months with no context. Specifics > generalities. Real file paths > vague references. Actual reasons > "best practice".
