#!/bin/bash
######################################################################
#  UTILITY SCRIPT NAME :  exdafs_hrrr_alaska_manager.sh
#
#  Abstract:  This script checks for upstream HRRR data availability
#             and triggers downstream JDAFS jobs
#
#  History:  07/16/2025
#              - initial version
#####################################################################

set -x

# Forecast hours for HRRR

hrrr_fhrs=$(seq -s ' ' 0 1 18)

# Forecast hours for JDAFS_UPP (CONUS & AK)
seq0="0"                    # 000
seq1=$(seq -s ' ' 1 1 18)   # 001 -> 018; 1-hourly
jdafs_upp_fhrs="${seq0} ${seq1}"

# Wait for all forecast hours to finish
MAX_ITER=1080
for ((iter = 1; iter <= MAX_ITER; iter++)); do

  # Loop over all HRRR forecast hours
  for fhr in ${hrrr_fhrs}; do

    fhr3=$(printf "%03d" "${fhr}")

    # Trigger jobs based on HRRR forecast output availability
    hrrr_sfc="${COMINhrrr}/hrrr_${cyc}f${fhr3}"
    if [[ -s "${hrrr_sfc}" ]] ; then

      # Release JDAFS_UPP_ALASKA forecast job for any forecast hour in the list
      if [[ " ${jdafs_upp_fhrs} " == *" ${fhr} "* ]]; then
        set +x
        echo "Releasing JDAFS_UPP_ALASKA job for fhr=${fhr3}"
        set -x
        ecflow_client --event "release_dafs_upp_alaska_${fhr3}"
      fi

      # Remove current fhr from list, once all jobs for the current fhr have been triggered
      hrrr_fhrs=$(echo "${hrrr_fhrs}" | sed "s/${fhr}//")
    fi

  done # end of loop over all HRRR forecast hours

  # Check if there are any forecast hours left to process
  check=$(echo "${hrrr_fhrs}" | wc -w)
  if ((check == 0)); then
    break
  fi

  # Sleep for 10 seconds before checking again
  sleep 10

done # end of loop over all iterations

if ((iter > MAX_ITER)); then
  err_exit "FATAL ERROR: ABORTING after 3 hours of waiting for HRRR forecast output at hours ${hrrr_fhrs}."
fi
