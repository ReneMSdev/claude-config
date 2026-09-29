---
name: new-project
description: Sets up a repo for the personal Claude Code workflow. Generates a project CLAUDE.md, docs/STATUS.md, docs/TODO.md, docs/decisions.md, and .claude/settings.json from templates, customized to the repo. Works on new and existing repos.
disable-model-invocation: true
argument-hint: "[optional one-line description of the project]"
---

Set up this repository for the user's workflow (their conventions are in the
user-level CLAUDE.md, already in your context). Project description from the
user (may be empty): $ARGUMENTS

Templates are in `${CLAUDE_SKILL_DIR}/templates/`. Read them all first.

## 1. Survey the repo

Work out as much as you can before asking anything:

- Stack and layout: languages, frameworks, package manifests, and whether it's
  a monorepo (several apps in subfolders, each with its own manifest).
- Commands: how to install, run, test, lint, type-check, and build. Look in
  manifests, Makefiles, CI workflows, READMEs, and scripts. Commands that CI
  actually runs are the most trustworthy.
- Existing Claude files: `CLAUDE.md`, `AGENTS.md`, `.claude/` (commands,
  skills, agents, settings).
- Existing tracking docs: anything like STATUS, TODO, HANDOFF, NOTES, or
  PROJECT_STATUS, at any level.

## 2. Confirm with the user

Show a short summary of what you found and ask only about what you couldn't
determine or aren't sure of. Typically:

- What the project is and its current stage (e.g. prototype, MVP, production).
- Whether the detected commands are right.
- Any project-specific rules (things agents must never do, style rules).
- Whether any role needs its own agent file. Explain that most projects don't:
  a subfolder `CLAUDE.md` already gives an agent working there the right
  context. A role needs a file only when it needs different tools or hard
  rules (e.g. a browser automation agent that must never submit a form).
- If tracking docs exist: fold them into the new files, or leave them alone?

## 3. Generate the files

Fill the templates with real content. Don't leave template placeholders in
the output, and don't invent facts: if something is unknown, leave it out or
write "unknown".

- `CLAUDE.md` (repo root). Keep it under about 60 lines: facts and rules, not
  procedures. If a `CLAUDE.md` or `AGENTS.md` exists, don't overwrite it.
  Propose additions and apply them only after the user agrees.
- `<subfolder>/CLAUDE.md` for each app in a monorepo: stack-specific commands
  and conventions only.
- `docs/STATUS.md`: describe the current state from what you surveyed. Mark
  anything you didn't run yourself as **unverified**. Don't copy "passing"
  claims from old docs as if they were verified.
- `docs/TODO.md`: seed it from existing TODO docs, open items in old status
  docs, and gaps you noticed. Keep it short and prioritized.
- `docs/decisions.md`: start with the header. If old docs record real
  decisions with reasons, carry the important ones over, marked as imported.
- `.claude/settings.json`: allow rules for the project's read-only and check
  commands (tests, lint, type-check) so they run without prompts. Merge into
  an existing file rather than replacing it.
- `.claude/agents/<role>.md`: only for roles the user confirmed.
- `.gitignore`: make sure `.claude/settings.local.json` and `CLAUDE.local.md`
  are ignored (use `**/` prefixes in monorepos).

If old tracking docs were folded in, ask before deleting them.

## 4. Finish

- Run the test command once so `docs/STATUS.md` starts with at least one
  verified fact. If it can't run here, say so in STATUS.
- List the files created or changed, and propose a commit with explicit
  paths. Wait for approval. Never push.
