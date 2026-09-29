#!/usr/bin/env bash
# PreToolUse hook (Bash): asks for approval before any git push, whatever form
# it takes (git push, git -C dir push, git -c k=v push, chained after && or ;).
# Backs up the Bash(git push:*) ask rule, whose prefix match misses those forms.
# Errs toward asking: a false positive costs one extra prompt.

python3 -c '
import json, re, sys

try:
    cmd = json.load(sys.stdin).get("tool_input", {}).get("command", "")
except Exception:
    sys.exit(0)

# Split into simple commands, then look for git ... push within one of them.
for part in re.split(r"&&|\|\||[;|\n]", cmd):
    if re.search(r"(^|[\s/])git\s(.*\s)?push(\s|$)", part):
        print(json.dumps({"hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "ask",
            "permissionDecisionReason": "git push needs your approval (claude-config confirm-push hook)",
        }}))
        break
'
exit 0
