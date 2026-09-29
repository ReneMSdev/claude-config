#!/usr/bin/env bash
# SessionStart hook: prints project state so every session (and every
# post-compaction context) starts oriented. Stdout is added to Claude's context.
# Stays silent outside git repos that don't use the docs/ convention.

dir="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$dir" 2>/dev/null || exit 0

in_git=false
git rev-parse --is-inside-work-tree >/dev/null 2>&1 && in_git=true
has_docs=false
[ -f docs/STATUS.md ] || [ -f docs/TODO.md ] && has_docs=true

$in_git || $has_docs || exit 0

echo "## Session context (from ~/.claude/hooks/session-start.sh)"

if $in_git; then
  echo
  echo "### Git"
  echo "Branch: $(git branch --show-current 2>/dev/null || echo '(detached)')"
  changes=$(git status --short 2>/dev/null)
  if [ -n "$changes" ]; then
    echo "Uncommitted changes ($(printf '%s\n' "$changes" | wc -l | tr -d ' ') files):"
    printf '%s\n' "$changes" | head -15
  else
    echo "Working tree clean."
  fi
  echo "Recent commits:"
  git log --oneline -5 2>/dev/null
fi

if [ -f docs/STATUS.md ]; then
  echo
  echo "### docs/STATUS.md (first 40 lines)"
  head -40 docs/STATUS.md
fi

if [ -f docs/TODO.md ]; then
  open=$(grep -E '^\s*- \[ \]' docs/TODO.md)
  if [ -n "$open" ]; then
    echo
    echo "### Open TODOs ($(printf '%s\n' "$open" | wc -l | tr -d ' ') total, first 8)"
    printf '%s\n' "$open" | head -8
  fi
fi

if $in_git && ! $has_docs; then
  echo
  echo "(No docs/STATUS.md here. /new-project can set up the state files.)"
fi

exit 0
