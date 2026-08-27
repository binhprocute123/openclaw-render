#!/bin/sh
set -eu

STATE_DIR="${OPENCLAW_STATE_DIR:-/tmp/openclaw-state}"
CONFIG_FILE="${STATE_DIR}/openclaw.json"

mkdir -p "$STATE_DIR"

echo "[restore] Checking OpenClaw backup..."

if [ -n "${BACKUP_REPO:-}" ] && [ -n "${GH_BACKUP_TOKEN:-}" ]; then
  TMP_FILE="${CONFIG_FILE}.tmp"

  if curl -fsSL \
    -H "Authorization: Bearer ${GH_BACKUP_TOKEN}" \
    -H "Accept: application/vnd.github.raw+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/${BACKUP_REPO}/contents/openclaw.json?ref=main" \
    -o "$TMP_FILE"; then

    mv "$TMP_FILE" "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"

    echo "[restore] openclaw.json restored successfully"
  else
    rm -f "$TMP_FILE"
    echo "[restore] WARNING: could not restore backup"
  fi
else
  echo "[restore] BACKUP_REPO or GH_BACKUP_TOKEN is missing"
fi

exec /usr/local/bin/proxy
