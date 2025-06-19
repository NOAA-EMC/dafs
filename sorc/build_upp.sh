#!/bin/bash

set -eu

# Get the root of the cloned WAFS directory
readonly DIR_ROOT=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}")")/.." && pwd -P)

# Check DAFS/exec folder exists
if [[ ! -d "${DIR_ROOT}/exec" ]]; then
  mkdir -p "${DIR_ROOT}/exec"
fi

# Build upp executable file
cd "${DIR_ROOT}/sorc/dafs_upp.fd/tests"
./compile_upp.sh -gi

# Copy upp to DAFS/exec
rm -rf "${DIR_ROOT}/exec/dafs_upp.x"
cp "${DIR_ROOT}/sorc/dafs_upp.fd/exec/upp.x" "${DIR_ROOT}/exec/dafs_upp.x"

exit
