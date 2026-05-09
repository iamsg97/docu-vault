#!/usr/bin/env bash
# Runs automatically after every Claude session via the Stop hook.
# Detects TypeScript/TSX source files modified more recently than the latest
# session learning doc and prints a reminder if undocumented work is found.
# Output is shown to the user in the Claude Code terminal.

SUMMARY_FILE="docs/learnings/SUMMARY.md"
SESSIONS_DIR="docs/learnings/sessions"

# Nothing to compare against yet — skip silently on first run.
if [ ! -f "$SUMMARY_FILE" ]; then
  exit 0
fi

# Use the most recently modified session doc as the reference point, falling
# back to SUMMARY.md if no session docs exist yet.
REFERENCE_FILE="$SUMMARY_FILE"
latest_session=$(find "$SESSIONS_DIR" -maxdepth 1 -name "*.md" -not -name "_template.md" \
  2>/dev/null | xargs ls -t 2>/dev/null | head -1)
if [ -n "$latest_session" ]; then
  REFERENCE_FILE="$latest_session"
fi

# Find source files newer than the reference, excluding generated/build artifacts.
recent_code=$(find apps lambdas packages \
  -type f \( -name "*.ts" -o -name "*.tsx" \) \
  -newer "$REFERENCE_FILE" \
  -not -path "*/node_modules/*" \
  -not -path "*/dist/*" \
  -not -path "*/.next/*" \
  -not -name "*.spec.ts" \
  -not -name "*.e2e-spec.ts" \
  2>/dev/null | head -5)

if [ -n "$recent_code" ]; then
  echo ""
  echo "┌──────────────────────────────────────────────────────────┐"
  echo "│  LEARNING DOC MISSING                                    │"
  echo "│                                                          │"
  echo "│  Source files changed since the last session doc.       │"
  echo "│  A 5-chunk learning doc should exist in:                │"
  echo "│  docs/learnings/sessions/YYYY-MM-DD-<task-slug>.md      │"
  echo "│                                                          │"
  echo "│  Chunks required: Conceptual · Functional · Product ·   │"
  echo "│                   System Design · Fundamentals           │"
  echo "│                                                          │"
  echo "│  /learn              — capture session learnings         │"
  echo "│  /feature-complete   — document a completed feature      │"
  echo "└──────────────────────────────────────────────────────────┘"
fi
