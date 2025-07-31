#!/bin/bash

set -eu

# Get the root of the cloned DAFS directory
readonly DIR_ROOT=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}")")/.." && pwd -P)

ECF_DIR="${DIR_ROOT}/ecf"

# Function that loops over forecast hours and
# creates link between the master and target
function link_master_to_fhr() {
  local tmpl=$1               # Name of the master template
  local fhrs=$2               # Array of forecast hours
  local clean_only=${3:-"NO"} # Clean only flag to remove existing links
  local fhr3 master target
  for fhr in ${fhrs[@]}; do
    fhr3=$(printf %03d ${fhr})
    if [[ "$tmpl" =~ "upp" ]] ; then
	master="jdafs_upp_master.ecf"
	target="jdafs_${tmpl}_f${fhr3}.ecf"
    else
	master="${tmpl}_master.ecf"
	target="${tmpl}_f${fhr3}.ecf"
    fi
    rm -f "${target}"
    case "${clean_only}" in
    "YES")
      continue
      ;;
    *)
      ln -sf "${master}" "${target}"
      ;;
    esac
  done
}

CLEAN=${1:-${CLEAN:-"NO"}} # Remove links only; do not create links (YES)

# JDAFS_UPP
cd "${ECF_DIR}/upp"
echo "Linking upp ..."
seq1=$(seq -s ' ' 1 1 18)   # 001 -> 018; 1-hourly
fhrs="${seq1}"
link_master_to_fhr "conus_upp" "${fhrs}" "${CLEAN}"
link_master_to_fhr "alaska_upp" "${fhrs}" "${CLEAN}"
