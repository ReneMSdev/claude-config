#!/usr/bin/env bash
# PreToolUse hook (Bash): asks for approval before any git push, whatever form
# it takes (git push, git -C dir push, git -c k=v push, chained after && or ;).
# This hook is the only push guard; there is no separate Bash(git push:*) ask rule.
# Errs toward asking: a false positive costs one extra prompt.
#
# Opt-in exception: a repo whose root has .claude/push-branches (one branch name
# or glob pattern per line, # comments allowed) may push those branches without a
# prompt, but only as a single plain command:
# `git push [-u|--set-upstream] origin <branch>`, run in that repo. Force, delete,
# refspecs, other remotes, chains and every other form still ask. The agent is
# expected to ask in chat before pushing.
#
# Patterns are matched with fnmatch (case-sensitive; * also crosses "/", so
# claude/* matches claude/a/b). The wildcards are * and ? only: a line containing
# [ or ] is ignored. A pattern with no letter or digit besides its wildcards
# (*, ?*, */*) is ignored too. Any other pattern matches whatever it matches
# (*ain matches main), so keep the lines narrow.

python3 -c '
import fnmatch, json, os, re, shlex, subprocess, sys

ASK = {"hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask",
    "permissionDecisionReason": "git push needs your approval (claude-config confirm-push hook)",
}}

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
cmd = data.get("tool_input", {}).get("command", "") or ""
cwd = data.get("cwd") or os.getcwd()

# Split into simple commands, then look for git ... push within one of them.
parts = re.split(r"&&|\|\||[;|&\n]", cmd)
if not any(re.search(r"(^|[\s/])git\s(.*\s)?push(\s|$)", p) for p in parts):
    sys.exit(0)

def allowed():
    # Whole command must be one plain push: no chaining, substitution or redirects.
    if re.search(r"[;&|<>`\n]|\$\(", cmd):
        return False
    try:
        argv = shlex.split(cmd)
    except ValueError:
        return False
    if argv[:2] != ["git", "push"]:
        return False
    args = [a for a in argv[2:] if a not in ("-u", "--set-upstream")]
    if len(args) != 2 or args[0] != "origin":
        return False
    branch = args[1]
    if branch.startswith("-") or not re.fullmatch(r"[A-Za-z0-9._/-]+", branch):
        return False
    try:
        root = subprocess.run(["git", "-C", cwd, "rev-parse", "--show-toplevel"],
                              capture_output=True, text=True, timeout=5).stdout.strip()
    except Exception:
        return False
    if not root:
        return False
    try:
        with open(os.path.join(root, ".claude", "push-branches")) as f:
            listed = {l.split("#")[0].strip() for l in f}
    except OSError:
        return False
    for entry in listed - {""}:
        # No bracket classes: a line with [ or ] is ignored, so fnmatch only ever
        # sees * and ? as wildcards.
        if "[" in entry or "]" in entry:
            continue
        if entry == branch:
            return True
        # A pattern line must keep a letter or digit besides its * and ?.
        if (re.search(r"[*?]", entry)
                and re.search(r"[A-Za-z0-9]", re.sub(r"[*?]", "", entry))
                and fnmatch.fnmatchcase(branch, entry)):
            return True
    return False

if allowed():
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "allow",
        "permissionDecisionReason": "plain push of a branch listed in .claude/push-branches",
    }}))
else:
    print(json.dumps(ASK))
'
exit 0
