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

# Define the list of .eqy files
EQY_FILES="holes_filler.eqy equivalence_resolver.eqy feature_accumulator.eqy row_buf.eqy window.eqy table_reader.eqy linkruncca.eqy"
EQY_PARAMS="-j 6"

# Counter for failed runs
fail_count=0    

# Use the argument if provided, else use the default list
if [[ -n "$1" ]]; then
    FILES_TO_RUN="$1"
else
    FILES_TO_RUN=$EQY_FILES
fi

# Loop through each file and run the eqy command
for file in $FILES_TO_RUN; do
    echo "Running eqy on $file..."
    if ! eqy $EQY_PARAMS -f "$file"; then
        echo "Error: eqy failed on $file"
        ((fail_count++))
    fi
done

# Final result
if [[ $fail_count -gt 0 ]]; then
    echo "$fail_count file(s) failed."
    exit 1
else
    echo "All files processed successfully."
    exit 0
fi
