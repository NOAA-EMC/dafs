#!/bin/bash
######################################################################
#  UTILITY SCRIPT NAME :  exdafs_manager.sh
#
#  Abstract:  This script checks for upstream HRRR model data availability
#             and triggers downstream JDAFS jobs
#
#  History:  07/16/2025 - Initial version
#            10/24/2025 - Combine two domain manager into one
#####################################################################

set -x

DOM=$(echo $DOMAIN | tr '[:lower:]' '[:upper:]')

# Forecast hours for JDAFS_FORECAST (CONUS & AK)
fhrs=$(seq -s ' ' 0 1 18)   # 001 -> 018; 1-hourly
jdafs_forecast_fhrs="${fhrs}"

# Wait for all forecast hours to finish
MAX_ITER=1080
for ((iter = 0; iter <= MAX_ITER; iter++)); do

  # Loop over all HRRR forecast hours
  for fhr in ${fhrs}; do

    fhr3=$(printf "%03d" "${fhr}")

    # Trigger jobs based on HRRR forecast output availability
    if [[ $DOMAIN == "conus" ]] ;  then
       model_data="${COMIN}/hrrr_${PDY}${cyc}f${fhr3}"
    else
	model_data="${COMIN}/hrrrak_${PDY}${cyc}f${fhr3}"
    fi

    if [[ -s "${model_data}" ]] ; then

      # Release $DOM JDAFS_FORECAST forecast job for any forecast hour in the list
      if [[ " ${jdafs_forecast_fhrs} " == *" ${fhr} "* ]]; then
        set +x
        echo "Releasing $DOM JDAFS_FORECAST job for fhr=${fhr3}"
        set -x
        ecflow_client --event "release_dafs_forecast_${DOMAIN}_${fhr3}"
      fi

      # Remove current fhr from list, once all jobs for the current fhr have been triggered
      fhrs=$(echo "${fhrs}" | sed "s/${fhr}//")
    fi

  done # end of loop over all HRRR forecast hours

  # Check if there are any forecast hours left to process
  check=$(echo "${fhrs}" | wc -w)
  if ((check == 0)); then
    break
  fi

  # Sleep for 10 seconds before checking again
  sleep 10

done # end of loop over all iterations

if ((iter > MAX_ITER)); then
  err_exit "FATAL ERROR: ABORTING after 3 hours of waiting for HRRR ${DOMAIN} forecast output at hours ${fhrs}."
fi
