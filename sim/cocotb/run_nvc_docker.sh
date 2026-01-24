#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

COCOTB_DEBUG="${COCOTB_DEBUG:-}"

LOCAL_PY="${ROOT_DIR}/venv/bin/python"
if [ -x "${LOCAL_PY}" ]; then
  PYTHON="${LOCAL_PY}"
else
  PYTHON="python3"
fi

if command -v nvc >/dev/null 2>&1 && "${PYTHON}" -c "import cocotb" >/dev/null 2>&1; then
  COCOTB_DEBUG="${COCOTB_DEBUG}" SIM="nvc" "${PYTHON}" "${ROOT_DIR}/sim/cocotb/runner.py"
  exit $?
fi

if command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_CMD="docker-compose"
elif docker compose version >/dev/null 2>&1; then
  COMPOSE_CMD="docker compose"
else
  echo "Error: docker-compose or docker compose plugin not found." >&2
  exit 1
fi

${COMPOSE_CMD} -f "${ROOT_DIR}/sim/cocotb/docker/docker-compose.yml" run --rm --service-ports \
  -u "$(id -u):$(id -g)" \
  -e DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix \
  -e HOME=/work/sim/cocotb/sim_build/tmp \
  -e MPLBACKEND=TkAgg \
  -e COCOTB_DEBUG -e SIM=nvc \
  nvc-cocotb \
  python /work/sim/cocotb/runner.py
