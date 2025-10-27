#!/bin/bash

set -eu

# Get the root of the cloned DAFS directory
readonly DIR_ROOT=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}")")/.." && pwd -P)

ECF_DIR="${DIR_ROOT}/ecf"

# Function that loops over forecast hours and
# creates ecf link between the forecast and target
function link_forecast_to_fhr() {
  local domain=$1             # Domain
  local fhrs=$2               # Array of forecast hours
  local clean_only=${3:-"NO"} # Clean only flag to remove existing links
  local fhr3 forecast target
  for fhr in ${fhrs[@]}; do
    fhr3=$(printf %03d ${fhr})
    forecast="jdafs_forecast.ecf"
    target="jdafs_forecast_${domain}_f${fhr3}.ecf"
    rm -f "${target}"
    case "${clean_only}" in
    "YES")
      continue
      ;;
    *)
      ln -sf "${forecast}" "${target}"
      ;;
    esac
  done
}

CLEAN=${1:-${CLEAN:-"NO"}} # Remove links only; do not create links (YES)

# JDAFS_FORECAST
cd "${ECF_DIR}/forecast"
echo "Linking forecast ..."
seq1=$(seq -s ' ' 0 1 18)   # 001 -> 018; 1-hourly
fhrs="${seq1}"
link_forecast_to_fhr "conus" "${fhrs}" "${CLEAN}"
link_forecast_to_fhr "alaska" "${fhrs}" "${CLEAN}"
