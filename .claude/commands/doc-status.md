Audit the current documentation state for the DocuVault project and produce a clear status report.

Run these checks in order:

---

## Check 1 — Documented features

Read `docs/features/index.md` and list every feature that has been documented, along with its status and date.

---

## Check 2 — Recent undocumented changes

Run this command to find source files modified more recently than the learnings summary:

```bash
find apps lambdas packages -type f \( -name "*.ts" -o -name "*.tsx" \) \
  -newer docs/learnings/SUMMARY.md \
  -not -path "*/node_modules/*" \
  -not -path "*/dist/*" \
  -not -path "*/.next/*" \
  -not -name "*.spec.ts" \
  -not -name "*.e2e-spec.ts" \
  2>/dev/null | sort
```

List any files found. These represent work that hasn't been documented yet.

---

## Check 3 — Recent learnings

Show the last 5 entries from `docs/learnings/SUMMARY.md` (the most recent dated sections).

---

## Check 4 — Infrastructure completeness

Verify these files exist and are non-empty:
- `docs/features/_template.md`
- `docs/learnings/functional/_template.md`
- `docs/learnings/technical/_template.md`
- `docs/learnings/design/_template.md`
- `docs/features/index.md`
- `.claude/settings.json`
- `.claude/scripts/check-pending-docs.sh`

---

## Report format

```
## DocuVault Documentation Status — [today's date]

### ✅ Documented Features ([count])
[table or list]

### ⚠️  Undocumented Recent Changes ([count] files)
[file list, or "none — all changes documented"]

### 📋 Recent Learnings (last 5)
[from SUMMARY.md]

### 🔧 Infrastructure
[file existence check results]
```

Be concise. The goal is a quick health check, not a full audit.
