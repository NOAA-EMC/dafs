#!/bin/bash
#

set -x

# ---- Get grib data at certain record # ----------------------
#
#  subset IFI for each variable at every 304 m & separate files 
#

dafs_ifi=$1

mkdir -p ${COMOUT}/wmo

domain=ak

#--------------------------------------------------------------- 

  fname1="${RUN}.t${cyc}z.ifi.icing.3km.${domain}.f${fhr}.grib2"

  #-- ALL ICING species 
  
  $WGRIB2 ${COMOUT}/${dafs_ifi}  | grep -F -f ${FIXdafs}/prdgen/dafs.ifi.sub304m.params | \
  $WGRIB2 -i ${COMOUT}/${dafs_ifi} -GRIB ${fname1}
  # $WGRIB2 -i ${COMOUT}/${dafs_ifi} -GRIB ${COMOUT}/${fname1}

  #================================================================
  #-- add WMO header only at certain forcast hour
  
  parm_dir=${PARMdafs}/wmo

  #-- remove the leading 0"
  ifhr=$(expr $fhr + 0)

  if [ $ifhr = 1 -o  $ifhr = 2 -o  $ifhr = 3 -o  $ifhr = 6 -o  $ifhr = 9 -o  $ifhr = 12 -o  $ifhr = 15 -o  $ifhr = 18 ]; then

     #-- all icing 

     parmfile=${parm_dir}/grib2.dafs.ifi.${fhr}      # parm file w/ header info
     infile=${fname1}
     # infile=${COMOUT}/${fname1}
     outfile=${COMOUT}/wmo/grib2.dafs.t${cyc}z.ifi.3km.${domain}.f${fhr}

     export FORT11=${infile}             # input file 
     export FORT12=                      # optional index file
     export FORT51=${outfile}            # output file w/ headers

     tocgrib2 < $parmfile 1>outfile.ifi.f${fhr}.$$

  fi
