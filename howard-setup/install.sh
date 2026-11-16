#!/usr/bin/env bash
# Usage:
#   install.sh wrapper            install codex-magpie.sh to ~/.local/bin (never overwrites)
#   install.sh project <repo>     merge ag.json.example into <repo>/.agentflow/ag.json
#   install.sh skill              link ~/.agents/skills/agentflow to this checkout (backs up, never deletes)
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
bin="${HOME}/.local/bin/codex-magpie"
case "${1-}" in
  wrapper)
    mkdir -p "$(dirname "$bin")"
    if [ -e "$bin" ]; then
      if cmp -s "$here/codex-magpie.sh" "$bin"; then echo "already installed: $bin"; else echo "exists and differs: $bin (not overwritten; compare with $here/codex-magpie.sh)" >&2; exit 1; fi
    else cp "$here/codex-magpie.sh" "$bin" && chmod +x "$bin" && echo "installed $bin"; fi ;;
  project)
    repo="${2:?usage: install.sh project <repo>}"; file="$repo/.agentflow/ag.json"
    [ -f "$file" ] || { echo "missing $file (run agf init first)" >&2; exit 1; }
    [ -x "$bin" ] || { echo "run: install.sh wrapper" >&2; exit 1; }
    cp "$file" "$file.bak-before-magpie"
    node - "$file" "$here/ag.json.example" "$bin" <<'JS'
const fs = require('fs'), [file, example, wrapper] = process.argv.slice(2)
const cfg = JSON.parse(fs.readFileSync(file, 'utf8'))
const add = JSON.parse(fs.readFileSync(example, 'utf8').split('__CODEX_MAGPIE__').join(wrapper))
for (const [key, value] of Object.entries(add)) cfg[key] = { ...(cfg[key] || {}), ...value }
fs.writeFileSync(file, JSON.stringify(cfg, null, 2) + '\n')
JS
    echo "merged into $file (backup: $file.bak-before-magpie); review: git -C $repo diff .agentflow/ag.json" ;;
  skill)
    target="${HOME}/.agents/skills/agentflow"
    if [ -L "$target" ]; then echo "already a link: $(readlink "$target")"; exit 0; fi
    if [ -e "$target" ]; then mv "$target" "$target.bak-$(date +%Y%m%d-%H%M%S)"; fi
    ln -s "$here/../skills/agentflow" "$target" && echo "linked $target -> $here/../skills/agentflow" ;;
  *) sed -n '2,6p' "$0"; exit 2 ;;
esac
