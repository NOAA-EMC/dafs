#!/bin/bash
#######################################################################
#  UTILITY SCRIPT NAME : ak_subset_ifi_304m.sh
#
#  Abstract:  This script subset every species in the AK IFI file at  
#  every 304m from the surface as defined in file "ak_subset_ifi_304m"
#  then add the WMO header to this new sebsetted file
#
#  History:  08/16/2024
#              - initial version
#####################################################################
set -x

# ---- Get grib data at certain record # ----------------------
#
#  subset IFI for each variable at every 304 m & separate files 
#

dafs_ifi=$1

domain=ak

cd "${COMOUT}" || err_exit "FATAL ERROR: Could not 'cd ${COMOUT}'; ABORT!"
mkdir -p ${COMOUT}/wmo

#--------------------------------------------------------------- 

  fname1="${RUN}.t${cyc}z.ifi.icing.3km.${domain}.f${fhr}.grib2"

  #-- ALL ICING species 
  
  cpreq ${FIXdafs}/prdgen/dafs.ifi.sub304m.params .

  $WGRIB2 ${dafs_ifi}  | grep -F -f dafs.ifi.sub304m.params | \
  $WGRIB2 -i ${dafs_ifi} -GRIB ${fname1}
  # $WGRIB2 -i ${COMOUT}/${dafs_ifi} -GRIB ${COMOUT}/${fname1}

  #================================================================
  #-- add WMO header only at certain forcast hour
  
  parm_dir=${PARMdafs}/wmo

  #-- remove the leading 0"
  ifhr=$(expr $fhr + 0)

  if [ $ifhr = 1 -o  $ifhr = 2 -o  $ifhr = 3 -o  $ifhr = 6 -o  $ifhr = 9 -o  $ifhr = 12 -o  $ifhr = 15 -o  $ifhr = 18 ]; then

     #-- all icing 

     parmfile=grib2.dafs.ifi.${fhr}      # parm file w/ header info
     infile=${fname1}
     # infile=${COMOUT}/${fname1}
     outfile=grib2.dafs.t${cyc}z.ifi.3km.${domain}.f${fhr}

     cpreq ${parm_dir}/${parmfile} .

     export FORT11=${infile}             # input file 
     export FORT12=                      # optional index file
     export FORT51=${outfile}            # output file w/ headers

     ${TOCGRIB2} < $parmfile 1>outfile.ifi.f${fhr}.$$

     export err=$?
     err_chk

     # Check if TOCGRIB2 succeeded in creating the output file
     if [[ ! -f "${FORT51}" ]]; then
        err_exit "FATAL ERROR: '${pgm}' failed to create '${FORT51}', ABORT!"
     fi
  fi

  # Send data to COM
  if [[ "${SENDCOM}" == "YES" ]]; then
     cpfs ${outfile} ${COMOUT}/wmo
  fi
