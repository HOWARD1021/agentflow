# Howard's Agentflow + Magpie setup

Upstream Agentflow plus `looper-limits.worker-timeout-minutes` (PR agfnow/agentflow#2) and a Magpie routing profile.

Requires: Node 20+, `codex` on PATH, a Magpie gateway (default `http://127.0.0.1:3425/v1`) exposing `group/tier-{best,better,basic,cheap}`.

1. `./install.sh wrapper` - installs `~/.local/bin/codex-magpie` (override with `CODEX_BIN`, `MAGPIE_BASE_URL`, `MAGPIE_TOKEN`).
2. `./install.sh skill` - links the skill from this checkout. Do not run while a Looper run is active.
3. `./install.sh project <repo>` - merges `ag.json.example` into a repo that already ran `agf init`. A backup is written next to the file; the JSON may be re-indented.

Tune routes, tiers and the timeout in `ag.json.example` before sharing. Never put tokens in this repo.

Design notes, branch roles and verification status: [DESIGN.zh-tw.md](DESIGN.zh-tw.md).
