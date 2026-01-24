# Cocotb Simulation

This folder contains a cocotb runner, a minimal testbench, and Docker tooling for running the design with GHDL or NVC.

## Quick Run

GHDL (default, Docker if GHDL is not available locally):

```bash
./run_ghdl_docker.sh
```

NVC (Docker):

```bash
docker-compose -f docker/docker-compose.yml build nvc-cocotb
./run_nvc_docker.sh
```

## Build Images

Build GHDL container:

```bash
docker-compose -f docker/docker-compose.yml build ghdl-cocotb
```

Build NVC container:

```bash
docker-compose -f docker/docker-compose.yml build nvc-cocotb
```

## Debug (VS Code)

1) Run with debug enabled:

```bash
COCOTB_DEBUG=1 bash run_ghdl_docker.sh
```

2) Attach VS Code using the "Attach cocotb (debugpy)" config in `.vscode/launch.json`.

Notes:
- The Docker flow maps port 5678; `run_ghdl_docker.sh` uses `--service-ports` so the port is visible.
- If you change Dockerfiles or dependencies, rebuild the image before running.

## Environment Variables

- `COCOTB_DEBUG`: any non-empty value to wait for debugger
- `GHDL_STD`, `GHDL_BUILD_ARGS`, `GHDL_RUN_ARGS`
- `NVC_STD`, `NVC_BUILD_ARGS`, `NVC_RUN_ARGS`
- `TOPLEVEL`, `COCOTB_TEST_MODULES`/`TEST_MODULE`
- `LINKRUNCCA_PKG`, `LINKRUNCCA_IMWIDTH`, `LINKRUNCCA_IMHEIGHT`

## Notes

- GHDL VPI does not expose VHDL record ports; use NVC or add a wrapper with flat ports for cocotb access.
