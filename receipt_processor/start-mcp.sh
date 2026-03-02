#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${HOME}/.receipt-processor/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: $ENV_FILE not found."
  echo "Copy .env.example there and fill in your credentials. See README.md."
  exit 1
fi

set -a
source "$ENV_FILE"
set +a

exec uvx workspace-mcp --tools gmail sheets drive --transport streamable-http
