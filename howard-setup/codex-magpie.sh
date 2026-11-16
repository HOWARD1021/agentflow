#!/usr/bin/env bash
# Wrapper that points `codex exec` at a Magpie gateway.
# Agentflow calls it as: codex-magpie.sh exec <codex exec flags...>
# Env overrides: CODEX_BIN, MAGPIE_BASE_URL, MAGPIE_TOKEN
set -euo pipefail
if [ "${1-}" != exec ]; then
  echo 'codex-magpie expects codex exec arguments' >&2
  exit 2
fi
shift
exec "${CODEX_BIN:-codex}" exec \
  -c 'model_provider="magpie"' \
  -c 'model_providers.magpie.name="magpie"' \
  -c "model_providers.magpie.base_url=\"${MAGPIE_BASE_URL:-http://127.0.0.1:3425/v1}\"" \
  -c 'model_providers.magpie.wire_api="responses"' \
  -c "model_providers.magpie.experimental_bearer_token=\"${MAGPIE_TOKEN:-magpie}\"" \
  -c "model_providers.magpie.http_headers={\"x-openai-actor-authorization\"=\"${MAGPIE_TOKEN:-magpie}\"}" \
  "$@"
