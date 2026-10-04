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
| Losing the thread between sessions or after compaction | A session-start hook injects git state, `docs/status.md`, and open TODOs automatically |
| Claiming work is done when it isn't | Conventions require evidence (command, result, commit) for every status claim |
| Grading its own work | A read-only `verifier` subagent checks claims in a fresh context |
| Pushing unreviewed work | Every `git push` asks for approval (enforced by a hook and a settings rule, not just instructed) |

## What's in it

```
claude/
├── CLAUDE.md                  # conventions for every project
├── settings.json              # merged into ~/.claude/settings.json
├── agents/verifier.md         # read-only skeptic subagent
├── hooks/
│   ├── session-start.sh       # prints project state at session start
│   └── confirm-push.sh        # asks before any git push, in any form
└── skills/
    ├── wrapup/                # /wrapup: verify, update state files, propose commit
    └── new-project/           # /new-project: scaffold a repo for this workflow
        └── templates/         # CLAUDE.md, status.md, todo.md, decisions.md, settings.json
```

### Per-project files (created by `/new-project`)

| File | Answers | Changes by |
|---|---|---|
| `CLAUDE.md` | What is this, how do I run and check it, what are the rules? | Rarely |
| `docs/status.md` | Where do things stand now, with evidence? | Rewritten by `/wrapup` |
| `docs/todo.md` | What's next and later? | Checked off and extended by `/wrapup` |
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

## Commands

What I type, and what happens.

| Command | Where | What it does |
|---|---|---|
| `/new-project [description]` | In Claude Code, once per repo | Sets up a repo for this workflow (details below) |
| `/wrapup [note]` | In Claude Code, at the end of a work session | Checks the session's work, updates the state files, proposes a commit (details below) |
| "have the verifier check …" | In Claude Code, any time | Runs the `verifier` subagent on whatever claims or changes I name |
| `~/Dev/claude-config/install.sh` | Terminal | Links this repo into `~/.claude/` and merges settings |

Claude never starts `/new-project` or `/wrapup` by itself. I have to type
them.

### `/new-project [description]`

Works on new and existing repos. The optional description is a one-line
summary of the project.

1. **Surveys the repo:** stack, layout (including monorepos), commands from
   manifests and CI, existing Claude files, and old tracking docs (STATUS,
   TODO, HANDOFF, and so on).
2. **Asks me** only what it couldn't work out: the project's stage, whether
   the detected commands are right, project-specific rules, whether any role
   needs its own agent file, and what to do with old tracking docs.
3. **Creates the files:** root `CLAUDE.md` (or proposes additions if one
   exists, and never overwrites it), a `CLAUDE.md` for each app in a
   monorepo, `docs/status.md`, `docs/todo.md`, `docs/decisions.md`,
   `.claude/settings.json` with allow rules for the check commands, and
   `.gitignore` entries for local-only Claude files.
4. **Runs the tests once** so STATUS starts with at least one verified fact,
   then proposes a commit with explicit paths and waits for my yes.

### `/wrapup [note]`

The optional note says what the session was for. If the repo has no
`docs/status.md`, it stops and suggests `/new-project`.

1. **Lists claims:** what the session did, from `git status`, the diff, and
   new commits, including things that were tried and didn't work.
2. **Runs the checks** from the **Commands** table in the project's
   `CLAUDE.md`, only for areas that changed, and records the real results.
3. **Sends the claims and results to `verifier`**, which marks each one
   CONFIRMED, REFUTED, or UNVERIFIED. Refuted claims don't get recorded as
   done.
4. **Updates the state files** with verified facts only: rewrites
   `status.md`, checks off and adds to `todo.md`, and appends real decisions
   to `decisions.md`.
5. **Reports and proposes a commit**, then waits for my yes. It never pushes.

### Automatic behavior

- **Every session start** (and after context compaction), the hook prints
  the branch, uncommitted changes, the last 5 commits, the first 40 lines of
  `docs/status.md`, and the first 8 open TODOs. It prints nothing outside git
  repos.
- **Every git push asks for my approval**, whatever form it takes (`git push`,
  `git -C <dir> push`, `git -c k=v push`, or chained after `&&` or `;`). The
  `confirm-push.sh` hook checks each Bash command before it runs. The
  `Bash(git push:*)` rule in settings is a second layer that only catches
  commands starting with `git push`. The hook errs toward asking, so a command
  like `git log --grep push` also prompts.

## Install

```sh
git clone https://github.com/ReneMSdev/claude-config.git ~/Dev/claude-config
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
