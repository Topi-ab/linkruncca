#!/bin/bash

# If we do not detect the /Dockerfile file, assume we are on host, and rerun inside Docker
if [[ ! -f /Dockerfile ]]; then
    exec docker run --rm -it \
        -v "$PWD/../../..:$PWD/../../.." \
        -w "$PWD" \
        -u "$(id -u):$(id -g)" \
        anybytes/yosys \
        ./$(basename "$0") "$@"
fi

sby -f formal_fa_comparator.sby "$@"
