---
date: YYYY-MM-DD
topic: short-topic-name
feature: feature-name-or-area
category: technical
---

# Technical Learning: [Topic Name]

## What This Covers

<!-- One paragraph: the technical area and why it's worth documenting. -->

## Implementation Pattern

<!-- The core pattern used. Name it precisely (e.g., "SQS long polling with visibility extension", "NestJS guard + Cognito JWT verification", "cursor pagination with Prisma"). -->

**Pattern:** [name]

How it's applied here:

```typescript
// Key code snippet showing the pattern — keep it short, focus on the non-obvious part
```

## Non-Obvious Decisions

<!-- Things that look wrong at first glance but are intentional, or subtleties that bit us. This is the most important section. -->

| Decision | Why it's correct | What breaks if you change it |
|----------|-----------------|------------------------------|
| | | |

## AWS / Library Configuration

<!-- Specific values and settings that matter. Wrong config here causes subtle bugs. -->

| Service/Setting | Value | Reason |
|-----------------|-------|--------|
| SQS visibility timeout | | |
| DynamoDB TTL attribute | | |
| | | |

## Performance and Cost Notes

<!-- Anything that affects latency, throughput, or the free tier budget. -->

-

## Debugging This Area

<!-- Practical guide: what to check when something goes wrong here. -->

1. First check: [what to look at]
2. Common failure mode: [symptom → cause → fix]
3. Useful commands:
   ```bash
   # e.g., inspect DynamoDB state
   aws dynamodb scan --endpoint-url http://localhost:8000 --table-name ProcessingJobs
   ```

## Key Files

<!-- The files a developer must read to understand this area. -->

- `path/to/file.ts` — what it does and why it matters
- `path/to/file.ts` — what it does and why it matters
