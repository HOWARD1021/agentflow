#!/usr/bin/env bash
# Usage:
#   install.sh wrapper                     install codex-magpie.sh to ~/.local/bin (never overwrites)
#   install.sh project [--dry-run] <repo>  merge ag.json.example into <repo>/.agentflow/ag.json and
#                                          <repo>/.agentflow/features/*/ag.json (backup: ag.json.bak-<YYYYMMDD-HHMMSS>);
#                                          --dry-run only lists the keys that would be added or changed
#   install.sh skill                       link ~/.agents/skills/agentflow to this checkout (old copy goes to ~/.agents/skill-backups/;
#                                          refuses unless this checkout is on howard-local)
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
    shift
    dry=0; repo=""
    for arg in "$@"; do
      case "$arg" in
        --dry-run) dry=1 ;;
        -*) echo "unknown option: $arg" >&2; exit 2 ;;
        *) [ -z "$repo" ] || { echo "unexpected argument: $arg" >&2; exit 2; }; repo="$arg" ;;
      esac
    done
    [ -n "$repo" ] || { echo "usage: install.sh project [--dry-run] <repo>" >&2; exit 2; }
    files=()
    if [ -f "$repo/.agentflow/ag.json" ]; then files+=("$repo/.agentflow/ag.json"); fi
    for f in "$repo"/.agentflow/features/*/ag.json; do
      if [ -f "$f" ]; then files+=("$f"); fi
    done
    [ "${#files[@]}" -gt 0 ] || { echo "no ag.json found in $repo/.agentflow or $repo/.agentflow/features/* (run agf init first)" >&2; exit 1; }
    [ -x "$bin" ] || { echo "run: install.sh wrapper" >&2; exit 1; }
    # All files are parsed and merged in memory first; nothing is written if any file fails.
    node - "$dry" "$(date +%Y%m%d-%H%M%S)" "$here/ag.json.example" "$bin" "${files[@]}" <<'JS'
const fs = require('fs'), { isDeepStrictEqual } = require('util')
const [dry, stamp, example, wrapper, ...files] = process.argv.slice(2)
const add = JSON.parse(fs.readFileSync(example, 'utf8').split('__CODEX_MAGPIE__').join(wrapper))
const show = v => JSON.stringify(v)
const has = (o, k) => Object.prototype.hasOwnProperty.call(o, k)

// Per-top-level-key shallow merge (unchanged); also reports which inner keys it adds or changes.
function merge(cfg) {
  const changes = []
  for (const [key, value] of Object.entries(add)) {
    const old = cfg[key] || {}
    for (const [k, v] of Object.entries(value)) {
      if (!has(old, k)) changes.push(`+ ${key}.${k} = ${show(v)}`)
      else if (!isDeepStrictEqual(old[k], v)) changes.push(`~ ${key}.${k}: ${show(old[k])} -> ${show(v)}`)
    }
    cfg[key] = { ...old, ...value }
  }
  return changes
}

// Timestamped backup; a same-second collision gets -1, -2, ... instead of overwriting.
function backup(file) {
  for (let n = 0; ; n++) {
    const bak = `${file}.bak-${stamp}${n ? `-${n}` : ''}`
    try { fs.copyFileSync(file, bak, fs.constants.COPYFILE_EXCL); return bak }
    catch (e) { if (e.code !== 'EEXIST') throw e }
  }
}

function main() {
  const plans = files.map(file => {
    try {
      const cfg = JSON.parse(fs.readFileSync(file, 'utf8'))
      return { file, cfg, changes: merge(cfg) }
    } catch (e) { throw new Error(`${file}: ${e.message}`) }
  })
  if (dry === '1') {
    for (const { file, changes } of plans) {
      console.log(`[dry-run] ${file}`)
      for (const c of changes) console.log(`  ${c}`)
      if (!changes.length) console.log('  (no key changes)')
    }
    console.log('dry-run: nothing written, no backups created')
    return
  }
  const backups = plans.map(p => backup(p.file))
  plans.forEach((p, i) => {
    fs.writeFileSync(p.file, JSON.stringify(p.cfg, null, 2) + '\n')
    console.log(`merged into ${p.file} (backup: ${backups[i]})`)
  })
}

try { main() } catch (e) { console.error(`error: ${e.message}`); process.exit(1) }
JS
    if [ "$dry" = 0 ]; then echo "review: git -C $repo diff .agentflow"; fi ;;
  skill)
    branch="$(git -C "$here" branch --show-current 2>/dev/null || true)"
    [ "$branch" = "howard-local" ] || { echo "refusing: fork checkout $here/.. is on '${branch:-<none>}', not howard-local" >&2; exit 1; }
    target="${HOME}/.agents/skills/agentflow"
    # Backups live outside ~/.agents/skills: every folder in there is loaded as a skill.
    backups="${HOME}/.agents/skill-backups"
    if [ -L "$target" ]; then echo "already a link: $(readlink "$target")"; exit 0; fi
    if [ -e "$target" ]; then
      mkdir -p "$backups"
      stamp="$(date +%Y%m%d-%H%M%S)"; dest="$backups/agentflow.bak-$stamp"; n=0
      while [ -e "$dest" ]; do n=$((n+1)); dest="$backups/agentflow.bak-$stamp-$n"; done
      mv "$target" "$dest" && echo "backed up to $dest"
    fi
    ln -s "$here/../skills/agentflow" "$target" && echo "linked $target -> $here/../skills/agentflow" ;;
  *) sed -n '2,8p' "$0"; exit 2 ;;
esac
