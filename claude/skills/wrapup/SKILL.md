---
name: wrapup
description: End-of-session accountability. Runs the project's checks, has the verifier subagent confirm what was done, updates docs/status.md, docs/todo.md, and docs/decisions.md with evidence, then proposes a commit.
disable-model-invocation: true
argument-hint: "[optional note about what this session was for]"
---

Wrap up this work session. Session note from the user (may be empty): $ARGUMENTS

If `docs/status.md` doesn't exist, stop and suggest running `/new-project` first.

## 1. Gather what changed

- Run `git status` and `git diff --stat`, and look at commits made during this
  session (`git log`, compared with what the session-start context showed).
- Write a short list of **claims**: each concrete thing this session did or
  changed ("added X", "fixed Y", "tests for Z pass"). Include claims about
  things that were attempted but didn't work.

## 2. Run the checks

- Map the changed paths (from step 1, including this session's commits) to
  areas. In a project with sides like `backend/` and `frontend/`, run the
  check commands listed under **Commands** in the project's `CLAUDE.md`
  (tests, lint, type-check, build) only for the sides with changed files.
  Skip the others, and say you skipped them.
- **Doc-only session** (only `*.md`, `docs/`, `.claude/` prompt or agent
  files, or other files no check reads): run no checks. Say so, and keep the
  existing evidence in `docs/status.md` as it is, since nothing it covers
  changed.
- Record each command's actual result. If a command can't run here (missing
  service, credentials), record it as not run and why.

## 3. Verify independently

Send the `verifier` subagent the claim list, the check results, and which
changes to look at. Don't skip this for non-trivial work: the point is that
the agent who did the work doesn't grade it. Scale the request to the
session: for a doc-only session, ask it only to confirm the doc claims
against the diff (no test runs). If the verifier already checked this
session's claims (e.g. a manager ran it per feature), don't run it again;
cite that result and verify only claims it didn't cover.

If the verifier refutes a claim, don't record it as done. Tell the user, and
either fix it (if small and clearly in scope) or record it as an open issue.

## 4. Update the state files

Only record what was verified. Use the evidence format from the user's
CLAUDE.md, e.g. `pytest: 122 passed (a1b2c3d, 2026-09-28)`. Use today's date
and the current short commit hash (note "uncommitted" when the changes aren't
committed yet).

- **`docs/status.md`**: update the affected sections so they describe the
  current state. Rewrite, don't append a log. Update the "Last verified" line.
- **`docs/todo.md`**: check off finished items (move them to "Done recently",
  keeping only about the last 10). Add follow-ups discovered this session under
  the right heading, and remove items that are no longer relevant.
- **`docs/decisions.md`**: append an entry for each real decision made this
  session (a choice between alternatives, with a reason). Skip it if none were
  made. Don't log routine work here.

## 5. Report and propose a commit

Give the user a short summary:

- What was verified, with evidence
- What was refuted or unverified, and why
- TODO changes
- A proposed commit: explicit file paths and a message

Then wait. Commit only after the user says yes. Never push.
