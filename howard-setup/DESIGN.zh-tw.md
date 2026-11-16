# 設計說明：Agentflow 修改版 + Magpie 設定

## 為什麼有這份修改

Looper 的 CLI worker 原本固定 20 分鐘逾時。一個 task 的普通審查、修正與再審查都在同一個 session 內，父 task 到期時，還在跑的審查也會被一起取消（`scripts/looper.js` 的審查交接、`scripts/looper-agent.js` 的計時）。實例：workout-app 的 G01/T01 在第二輪審查時被終止。

修改：新增 `looper-limits.worker-timeout-minutes`（整數 1–1440，預設 20）。
- 讀取與驗證：`scripts/looper.js` 的 `read_settings`
- 傳入 worker：`scripts/looper.js` 啟動 `launch_agent` 處
- 實際計時：`scripts/looper-agent.js`，並記入 attempt 的 `launch.json`

只改這個數字即可，不必改程式。計時仍涵蓋整個 session（含等審查時間），沒有分階段預算，也沒有停滯偵測。

## 分支

| 分支 | 用途 |
|---|---|
| `main` | 上游複本，不放自己的修改 |
| `worker-timeout-setting` | 給上游 PR #2，只含逾時功能與測試，保持乾淨 |
| `howard-local` | 實際使用的完整版：上游 + 逾時功能 + 新專案預設 60 分鐘 + Magpie 模板 + `howard-setup/` |

上游更新：
```bash
git fetch origin && git checkout main && git merge --ff-only origin/main
git checkout howard-local && git merge main
```

## 目前各專案用哪個設定

路由寫在各專案自己的 `.agentflow/ag.json`，新 session 依「在哪個專案開」決定：

| 專案 | 執行檔 | 模型系列 | 逾時 |
|---|---|---|---|
| Magpie | `~/.local/bin/codex-magpie` | `magpie` | 60 |
| workout-app | 專案內 `.agentflow/codex-magpie.sh` | `openai` | 60 |
| 新初始化的專案 | `~/.local/bin/codex-magpie`（全域模板） | `magpie` | 60 |

全域模板只影響新專案，不會改既有專案。

## 兩份 codex-magpie 腳本

`~/.local/bin/codex-magpie` 與 `howard-setup/codex-magpie.sh` 功能相同：載入 Magpie provider 並保留 Agentflow 的隔離參數。差別只在新版可用 `CODEX_BIN`、`MAGPIE_BASE_URL`、`MAGPIE_TOKEN` 覆蓋，且用 PATH 上的 `codex`。本機的 `.bun/bin/codex` 只是指向 homebrew `codex` 的連結。

workout-app 專案內的腳本不同：它依賴 Codex 使用者設定裡已有 magpie provider。

## 可分享與不可分享

- 可分享：`howard-setup/`（佔位符 `__CODEX_MAGPIE__` 在安裝時才換成實際路徑）。
- 不可分享：`howard-local` 的技能模板（提交 `c0c2627`）寫死 `/Users/howard/.local/bin/codex-magpie` 與 `use-lang: zh`。別人用 `agf init` 會得到指向不存在檔案的路由。給別人用之前，要改成中性模板，並請對方用 `install.sh project <repo>`。
- 對方需要自己的 Magpie 服務（預設 `http://127.0.0.1:3425/v1`）與 `group/tier-{best,better,basic,cheap}` 模型。

## 已驗證與未驗證

已驗證：
- 用真實 `launch_agent` 加假 CLI（只會睡眠）測試：設 1 分鐘時 62 秒後 `Worker timed out`，`launch.json` 為 `timeout_ms: 60000`；設 60 為 `3600000`；未設為 `1200000`。
- 設定驗證測試（0、1441、1.5、字串皆拒絕；預設 20）。
- `install.sh wrapper` 與 `project` 在沙盒 HOME 內可用。

未驗證：
- 用真實 `codex` 與模型跑過 60 分鐘設定。
- 「task 等審查時不被提早取消」的完整情境。
- `install.sh skill`。
- 完整 `looper.test.js` 中 `dependency graphs start from checked integrated files and ancestry` 在本機會逾時（原版也會），與本修改無關。

## 注意事項

- 安裝目錄 `~/.agents/skills/agentflow` 是拷貝，不是連到 clone 的連結；`install.sh skill` 可改成連結。有 Looper run 進行中時不要替換。
- 逾時延長後，真正卡死的 worker 也會多佔最多 60 分鐘。
- 已停在 `working` 的 run 要先確認舊 worker 已停止才能續跑，不要手動改 `queue.json`。
- 不要在 repo 放任何 token。
