Capture learnings from this session and write them to the appropriate documentation files.

This command works even when no full feature was completed — partial work, technical discoveries, debugging insights, and architecture decisions are all worth persisting.

---

## Step 1 — Reflect on the session

Think through what happened:
- Which files were read, created, or modified?
- What technical decisions were made, and why those choices over alternatives?
- What did you discover about AWS services, NestJS patterns, or the existing codebase?
- What problems were encountered, and how were they resolved (or why were they deferred)?
- What would be non-obvious to a developer picking this up cold?

---

## Step 2 — Write learning documents

For each significant insight, create a file in the right category. Name files descriptively based on the topic, not the date (e.g., `sqs-visibility-timeout-tradeoff.md`, `cognito-jwt-refresh-flow.md`, `pgvector-chunk-strategy.md`). If a file for this topic already exists, update it instead of creating a duplicate.

**Functional learnings** → `docs/learnings/functional/`
Document: business logic, domain rules, user flows, feature behavior, integration points between services. Use `docs/learnings/functional/_template.md`.

**Technical learnings** → `docs/learnings/technical/`
Document: implementation patterns, library/SDK quirks, AWS configuration details, debugging discoveries, performance insights, non-obvious code decisions. Use `docs/learnings/technical/_template.md`.

**Design learnings** → `docs/learnings/design/`
Document: architectural patterns applied, trade-off decisions, why one approach was chosen over another, how components fit into the larger system. Use `docs/learnings/design/_template.md`.

Only write files where there is a genuine insight to record. Skip categories where nothing meaningful happened.

---

## Step 3 — Update SUMMARY.md

Add a new dated entry to `docs/learnings/SUMMARY.md`. Format:

```
### [YYYY-MM-DD] Session: [brief topic description]
- **[Functional|Technical|Design]** [Topic name]: [One sentence capturing the key insight]. See `docs/learnings/[category]/[filename].md`
```

Rules for SUMMARY.md:
- One line per learning — this file is injected into every future session, so brevity matters
- Each line must be self-contained enough to be useful without opening the linked file
- Group entries under date headings, newest first
- If you updated an existing doc rather than creating a new one, still add a SUMMARY entry referencing it

---

## Step 4 — Honest uncertainty

If a decision was made under uncertainty or time pressure, say so. Document known downsides explicitly. A learning that says "we chose X but Y might be better if Z happens" is more valuable than one that only states the positive.
