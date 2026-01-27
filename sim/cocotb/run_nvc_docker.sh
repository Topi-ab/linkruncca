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

DOCKER_FLAGS=(
  -u "$(id -u):$(id -g)"
  -e DISPLAY
  -e HOME=/work/sim/cocotb/sim_build/tmp
  -e MPLCONFIGDIR=/work/sim/cocotb/sim_build/tmp/matplotlib
  -e MPLBACKEND=TkAgg
  -e COCOTB_DEBUG
)

if [ -n "${DISABLE_PLOT:-}" ]; then
  DOCKER_FLAGS+=(-e DISABLE_PLOT)
fi

# Prefer the WSLg X11 socket when available (snap docker cannot mount /tmp/.X11-unix).
X11_SOCKET_DIR="/tmp/.X11-unix"
if [ -d /mnt/wslg/.X11-unix ]; then
  X11_SOCKET_DIR="/mnt/wslg/.X11-unix"
fi
DOCKER_FLAGS+=(
  -v "${X11_SOCKET_DIR}:/tmp/.X11-unix"
)

# WSLg support: pass through display/audio env and sockets when available.
if [ -d /mnt/wslg ]; then
  DOCKER_FLAGS+=(
    -e WAYLAND_DISPLAY
    -e XDG_RUNTIME_DIR
    -e PULSE_SERVER
    -v /mnt/wslg:/mnt/wslg
  )
fi

${COMPOSE_CMD} -f "${ROOT_DIR}/sim/cocotb/docker/docker-compose.yml" run --rm --service-ports \
  "${DOCKER_FLAGS[@]}" \
  nvc-cocotb \
  python /work/sim/cocotb/runner.py
