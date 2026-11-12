# Personal conventions (all projects)

These apply in every project. A project's own `CLAUDE.md` adds to them and wins
where the two conflict.

## Project state

Projects set up with `/new-project` keep their state in three files:

- `docs/status.md`: where things stand now, with evidence. Rewritten, not appended.
- `docs/todo.md`: what's next and later. A checklist.
- `docs/decisions.md`: why things are the way they are. Append-only.

A session-start hook prints a summary of these plus git state. Treat them as a
starting point, not ground truth: if they disagree with the code or git
history, say so instead of trusting the docs.

Run `/wrapup` at the end of a work session to update these files. It verifies
whatever the verifier or a passing gate hasn't already covered. Don't update
`status.md` with claims you haven't verified.

## Verification

- "Done" means verified. Run the relevant test, lint, or build command and read
  its output. Never report a check as passing unless it ran in this session.
- Attach evidence to status claims: the command, the result, the commit, and
  the date. Example: `pytest: 122 passed (a1b2c3d, 2026-09-28)`.
- If something couldn't be verified, mark it **unverified** and say why. An
  honest gap is better than a confident guess.
- Before calling non-trivial work complete, have the `verifier` subagent check
  the claims. Don't grade your own work. When a manager session delegates to
  worker agents, the manager runs the verifier, once per feature; workers don't
  run their own. `/wrapup` doesn't repeat a verifier pass that already covers
  the work.

## Git

- Stage explicit paths. Don't use `git add -A` or `git add .` without reviewing
  what it picks up.
- Commit when asked, or propose a commit at the end of `/wrapup` and wait for a
  yes.
- Pushes need approval (enforced by the confirm-push hook). A repo can opt in
  with `.claude/push-branches`: plain pushes of the branches it lists skip the
  permission prompt, but still ask me in chat first.
- The two rules above are the default, for projects without an automated
  gate. A project whose `CLAUDE.md` names a gate (one check script that hooks
  and CI both run) may set its own commit and push rule, and that rule wins
  there.
- Never rewrite history that has been pushed without asking first.

## Scope

- Do what was asked. When you notice something else worth doing, add it to
  `docs/todo.md` or mention it, rather than doing it unasked.
- Ask when a decision is genuinely mine to make; otherwise pick the sensible
  default and say which one you picked.

## Truthfulness

- Don't state skills, numbers, results, or features that aren't real or
  verifiable, in code comments, docs, READMEs, or anything user-facing.
- Anything I state directly in conversation counts as fact and can be used.
- Leave something out or ask, rather than guess or round up.
- Flag claims that are built but not yet proven (e.g. untested against real
  use) instead of implying they're proven.
