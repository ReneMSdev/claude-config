# claude-config

My personal [Claude Code](https://code.claude.com) setup: a lightweight,
repeatable workflow for working with coding agents across projects as a solo
developer, built around accountability. Agents verify before they claim, a
separate agent checks the claims, and project state lives in the repo.

## The problem it solves

Long agent sessions fail in predictable ways. They declare work done after
partial progress, they rate their own work too highly, and they lose track of
the original goal as context gets compacted. Status notes written by agents
drift from reality ("all tests passing" when nobody ran them).

This setup counters each of those with a small number of pieces:

| Failure | Countermeasure |
|---|---|
| Losing the thread between sessions or after compaction | A session-start hook injects git state, `docs/STATUS.md`, and open TODOs automatically |
| Claiming work is done when it isn't | Conventions require evidence (command, result, commit) for every status claim |
| Grading its own work | A read-only `verifier` subagent checks claims in a fresh context |
| Pushing unreviewed work | `git push` always asks for approval (enforced in settings, not just instructed) |

## What's in it

```
claude/
├── CLAUDE.md                  # conventions for every project
├── settings.json              # merged into ~/.claude/settings.json
├── agents/verifier.md         # read-only skeptic subagent
├── hooks/session-start.sh     # prints project state at session start
└── skills/
    ├── wrapup/                # /wrapup: verify, update state files, propose commit
    └── new-project/           # /new-project: scaffold a repo for this workflow
        └── templates/         # CLAUDE.md, STATUS.md, TODO.md, decisions.md, settings.json
```

### Per-project files (created by `/new-project`)

| File | Answers | Changes by |
|---|---|---|
| `CLAUDE.md` | What is this, how do I run and check it, what are the rules? | Rarely |
| `docs/STATUS.md` | Where do things stand now, with evidence? | Rewritten by `/wrapup` |
| `docs/TODO.md` | What's next and later? | Checked off and extended by `/wrapup` |
| `docs/decisions.md` | Why is it this way? | Appended |

These live in each repo, so they travel with it to any machine or cloud
session.

## Daily loop

1. **Start a session.** The hook shows branch, uncommitted changes, recent
   commits, current status, and open TODOs.
2. **Work.**
3. **`/wrapup`.** Runs the project's checks, has `verifier` confirm or refute
   what was claimed, updates the state files with only verified facts, and
   proposes a commit.

## Install

```sh
git clone <this repo> ~/Dev/claude-config
~/Dev/claude-config/install.sh
```

The installer symlinks `CLAUDE.md`, agents, skills, and hooks into
`~/.claude/`, so editing files here takes effect immediately. It merges
`settings.json` rather than linking it, because Claude Code writes its own
settings there. Anything it would replace is moved aside to `*.bak-<timestamp>`.
It's safe to re-run.

Then, in any repo: `/new-project`.

## Design choices

- **Enforce, don't just instruct.** Rules that matter go in settings and
  hooks, which can't be forgotten. `CLAUDE.md` holds conventions.
- **One verifier, not an agent team.** For one developer, a single independent
  check at the end of a session gets most of the value of multi-agent review
  at a fraction of the cost.
- **Roles only when needed.** A subfolder `CLAUDE.md` gives an agent enough
  context for most roles. A dedicated agent file is for roles that need
  different tools or hard limits.
