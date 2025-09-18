#!/bin/bash

set -eu

# Get the root of the cloned DAFS directory
readonly DIR_ROOT=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}" )" )/.." && pwd -P)

cd "${DIR_ROOT}"

# Checkout upp and gtg code
git -c submodule."post_gtg.fd".update=checkout submodule update --init --recursive
git -c submodule."sorc/libIFI.fd".update=checkout submodule update --init --recursive

# upp:
cd "${DIR_ROOT}/sorc/dafs_upp.fd"

#Restrict the IFI code
chmod -R go-rwx sorc/libIFI.fd

# copy DAFS specific UPP parm/ files to the main vertical structure
mkdir -p "${DIR_ROOT}/parm/upp"
upp_parm_files=(hrrr_postcntrl_dafs.xml\
		postxconfig-NT-hrrr_dafs.txt)
for upp_parm_file in "${upp_parm_files[@]}"; do
  rm -f "${DIR_ROOT}/parm/upp/${upp_parm_file}"
  cp "parm/dafs/${upp_parm_file}" "${DIR_ROOT}/parm/upp/${upp_parm_file}"
done
gtg_parm_files=(gtg.config.hrrr \
		gtg.input.hrrr)
for gtg_parm_file in "${gtg_parm_files[@]}"; do
    rm -f "${DIR_ROOT}/parm/upp/${gtg_parm_file}"
    cp "sorc/ncep_post.fd/post_gtg.fd/${gtg_parm_file}" "${DIR_ROOT}/parm/upp/${gtg_parm_file}"
done

exit
