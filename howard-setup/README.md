# Howard's Agentflow + Magpie setup

Upstream Agentflow plus `looper-limits.worker-timeout-minutes` (PR agfnow/agentflow#2) and a Magpie routing profile.

Requires: Node 20+, `codex` on PATH, a Magpie gateway (default `http://127.0.0.1:3425/v1`) exposing `group/tier-{best,better,basic,cheap}`.

1. `./install.sh wrapper` - installs `~/.local/bin/codex-magpie` (override with `CODEX_BIN`, `MAGPIE_BASE_URL`, `MAGPIE_TOKEN`).
2. `./install.sh skill` - links the skill from this checkout (refuses unless the checkout is on `howard-local`). The old copy is moved to `~/.agents/skill-backups/`, outside the skills folder so it is not loaded as a skill. Do not run while a Looper run is active.
3. `./install.sh project [--dry-run] <repo>` - merges `ag.json.example` into `<repo>/.agentflow/ag.json` and `<repo>/.agentflow/features/*/ag.json` (repo must already have run `agf init`). Each file gets a backup `ag.json.bak-<YYYYMMDD-HHMMSS>` next to it; the JSON may be re-indented. `--dry-run` only lists the keys that would be added or changed.

Tune routes, tiers and the timeout in `ag.json.example` before sharing. Never put tokens in this repo.

Design notes, branch roles and verification status: [DESIGN.zh-tw.md](DESIGN.zh-tw.md).
