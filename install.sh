#!/usr/bin/env bash
# Links this repo's Claude Code config into ~/.claude and merges settings.
# Safe to re-run. Anything it would replace is moved aside to *.bak-<timestamp>.
set -euo pipefail

repo="$(cd "$(dirname "$0")" && pwd)"
src="$repo/claude"
dest="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
stamp="$(date +%Y%m%d-%H%M%S)"

link() {  # link <source> <target>
  local from="$1" to="$2"
  mkdir -p "$(dirname "$to")"
  if [ -L "$to" ] && [ "$(readlink "$to")" = "$from" ]; then
    echo "  ok       ${to#$dest/}"
    return
  fi
  if [ -e "$to" ] || [ -L "$to" ]; then
    mv "$to" "$to.bak-$stamp"
    echo "  backup   ${to#$dest/} -> $(basename "$to").bak-$stamp"
  fi
  ln -s "$from" "$to"
  echo "  linked   ${to#$dest/}"
}

echo "Linking into $dest"
link "$src/CLAUDE.md" "$dest/CLAUDE.md"
for f in "$src"/agents/*.md; do link "$f" "$dest/agents/$(basename "$f")"; done
for d in "$src"/skills/*/; do d="${d%/}"; link "$d" "$dest/skills/$(basename "$d")"; done
for f in "$src"/hooks/*; do chmod +x "$f"; link "$f" "$dest/hooks/$(basename "$f")"; done

# settings.json is merged, not linked: Claude Code writes to it (e.g. /config),
# and those local changes shouldn't end up in this repo.
echo "Merging settings into $dest/settings.json"
python3 - "$src/settings.json" "$dest/settings.json" "$stamp" <<'PY'
import json, os, shutil, sys
src_path, dest_path, stamp = sys.argv[1:]
src = json.load(open(src_path))
dest = json.load(open(dest_path)) if os.path.exists(dest_path) else {}
before = json.dumps(dest, sort_keys=True)

for kind, rules in src.get("permissions", {}).items():
    have = dest.setdefault("permissions", {}).setdefault(kind, [])
    have += [r for r in rules if r not in have]

for event, groups in src.get("hooks", {}).items():
    have = dest.setdefault("hooks", {}).setdefault(event, [])
    existing = {h.get("command") for g in have for h in g.get("hooks", [])}
    for g in groups:
        if not any(h.get("command") in existing for h in g.get("hooks", [])):
            have.append(g)

# Top-level settings this repo owns outright (e.g. attribution): repo value wins.
for key in ("attribution",):
    if key in src:
        dest[key] = src[key]

if json.dumps(dest, sort_keys=True) == before:
    print("  ok       settings already up to date")
else:
    if os.path.exists(dest_path):
        shutil.copy(dest_path, f"{dest_path}.bak-{stamp}")
        print(f"  backup   settings.json -> settings.json.bak-{stamp}")
    json.dump(dest, open(dest_path, "w"), indent=2)
    open(dest_path, "a").write("\n")
    print("  merged   permissions, hooks, attribution")
PY
echo "Done. New sessions pick this up; running sessions may need a restart for hooks."
