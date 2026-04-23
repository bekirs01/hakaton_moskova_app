#!/usr/bin/env bash
# Loads ./.env and runs Flutter with dart-define (Supabase + MemeOps API; no OpenAI in the app).
set -euo pipefail
cd "$(dirname "$0")"
if [[ -f .env ]]; then
  set -a
  # shellcheck source=/dev/null
  . ./.env
  set +a
fi
exec flutter run \
  --dart-define=SUPABASE_URL="${SUPABASE_URL:-}" \
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}" \
  --dart-define=MEMEOPS_API_BASE="${MEMEOPS_API_BASE:-http://127.0.0.1:3000}" \
  "$@"
