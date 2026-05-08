#!/usr/bin/env bash
# Runs automatically after every Claude session via the Stop hook.
# Detects TypeScript/TSX source files modified more recently than the learnings
# summary and prints a reminder if undocumented work is found.
# Output is shown to the user in the Claude Code terminal.

SUMMARY_FILE="docs/learnings/SUMMARY.md"

# Nothing to compare against yet — skip silently on first run.
if [ ! -f "$SUMMARY_FILE" ]; then
  exit 0
fi

# Find source files newer than the summary, excluding generated/build artifacts.
recent_code=$(find apps lambdas packages \
  -type f \( -name "*.ts" -o -name "*.tsx" \) \
  -newer "$SUMMARY_FILE" \
  -not -path "*/node_modules/*" \
  -not -path "*/dist/*" \
  -not -path "*/.next/*" \
  -not -name "*.spec.ts" \
  -not -name "*.e2e-spec.ts" \
  2>/dev/null | head -5)

if [ -n "$recent_code" ]; then
  echo ""
  echo "┌─────────────────────────────────────────────────────┐"
  echo "│  📚  DOCUMENTATION REMINDER                         │"
  echo "│                                                     │"
  echo "│  Source files were changed since the last learning  │"
  echo "│  capture. Consider running one of:                  │"
  echo "│                                                     │"
  echo "│  /learn              — capture session learnings    │"
  echo "│  /feature-complete   — document a completed feature │"
  echo "└─────────────────────────────────────────────────────┘"
fi
