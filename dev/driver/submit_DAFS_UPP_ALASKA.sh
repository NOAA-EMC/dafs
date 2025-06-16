#!/bin/bash

set -eu

# Get the root of the cloned DAFS directory
readonly DIR_ROOT=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}")")/../.." && pwd -P)
PDYcyc=${1}

tmpdir=/lfs/h2/emc/ptmp/${USER}/working_dafs_${PDYcyc}
mkdir -p $tmpdir
cd $tmpdir

jobcard=run_DAFS_UPP_ALASKA
cp "${DIR_ROOT}/dev/driver/${jobcard}" .

for (( ifhr=8; ifhr<=9; ifhr++ )); do
  fhr=$(printf "%03d" $ifhr)
  sed -e "s|HOMEdafs=.*|HOMEdafs=$DIR_ROOT|g" \
  -e "s|PDY=.*|PDY=${PDYcyc:0:8}|g" \
  -e "s|cyc=.*|cyc=${PDYcyc:8:2}|g" \
  -e "s|fhr=.*|fhr=$fhr|g" \
  $jobcard >$jobcard.$fhr

  qsub $jobcard.$fhr
done

