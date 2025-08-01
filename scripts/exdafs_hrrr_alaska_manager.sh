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

DOM=$(echo $dom | tr '[:lower:]' '[:upper:]')

# Forecast hours for HRRR

hrrr_fhrs=$(seq -s ' ' 1 1 18)

# Forecast hours for JDAFS_UPP (CONUS & AK)
seq1=$(seq -s ' ' 1 1 18)   # 001 -> 018; 1-hourly
jdafs_upp_fhrs="${seq1}"

# Wait for all forecast hours to finish
MAX_ITER=1080
for ((iter = 1; iter <= MAX_ITER; iter++)); do

  # Loop over all HRRR forecast hours
  for fhr in ${hrrr_fhrs}; do

    fhr3=$(printf "%03d" "${fhr}")

    # Trigger jobs based on HRRR forecast output availability
    hrrr_data="${COMINhrrr}/hrrrak_${PDY}${cyc}f${fhr3}"
    if [[ -s "${hrrr_data}" ]] ; then

      # Release $DCOM JDAFS_UPP forecast job for any forecast hour in the list
      if [[ " ${jdafs_upp_fhrs} " == *" ${fhr} "* ]]; then
        set +x
        echo "Releasing $DOM JDAFS_UPP job for fhr=${fhr3}"
        set -x
        ecflow_client --event "release_dafs_${dom}_upp_${fhr3}"
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
  err_exit "FATAL ERROR: ABORTING after 3 hours of waiting for HRRR ${dom} forecast output at hours ${hrrr_fhrs}."
fi
