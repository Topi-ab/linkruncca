#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_CMD="docker-compose"
elif docker compose version >/dev/null 2>&1; then
  COMPOSE_CMD="docker compose"
else
  echo "Error: docker-compose or docker compose plugin not found." >&2
  exit 1
fi

${COMPOSE_CMD} -f "${ROOT_DIR}/sim/cocotb/docker/docker-compose.yml" build
