---
date: YYYY-MM-DD
topic: short-topic-name
feature: feature-name-or-area
category: functional
---

# Functional Learning: [Topic Name]

## Problem Statement

<!-- The user or business problem this addresses. One paragraph. -->

## User Flow

<!-- Step-by-step from user action to system outcome. Be concrete — name the actual services, tables, and queues. -->

1. User does X on the frontend (`/upload` page)
2. Frontend calls BFF at `POST /api/v1/...`
3. BFF calls `document-service` at `POST /documents`
4. ...

## Business Rules

<!-- Invariants that must always hold. If the code enforces them, reference the file/line. -->

- Rule: explanation of why it matters
- Rule: explanation of why it matters

## Edge Cases Handled

<!-- Non-obvious situations the code accounts for. What happens at boundaries, with bad input, with partial failures. -->

| Scenario | How it's handled | Where in code |
|----------|-----------------|---------------|
| | | |

## Edge Cases Deferred

<!-- Things the code intentionally does NOT handle yet. Useful so future devs don't assume coverage. -->

- Scenario: why it was deferred

## Integration Points

<!-- Every service, table, queue, or external system this feature touches. -->

| System | What it reads/writes | Why |
|--------|---------------------|-----|
| PostgreSQL `documents` table | | |
| SQS `processing-queue` | | |
| S3 bucket | | |

## Known Limitations

<!-- Current constraints the next developer should know about. -->

-
