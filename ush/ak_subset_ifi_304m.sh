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

  fname1="${RUN}.t${cyc}z.ifi.icp.3km.${domain}.f${fhr}.grib2"
  fname2="${RUN}.t${cyc}z.ifi.sld.3km.${domain}.f${fhr}.grib2"
  fname3="${RUN}.t${cyc}z.ifi.sev.3km.${domain}.f${fhr}.grib2"

  #-- ICPRB
  
  $WGRIB2 ${COMOUT}/${dafs_ifi} -s | grep ":ICPRB:" | grep -F -f ${FIXdafs}/prdgen/dafs.ifi.sub304m.params | \
  $WGRIB2 -i ${COMOUT}/${dafs_ifi} -GRIB ${COMOUT}/${fname1}

  #-- sipd
  
  $WGRIB2 ${COMOUT}/${dafs_ifi} -s | grep ":SIPD:"  | grep -F -f ${FIXdafs}/prdgen/dafs.ifi.sub304m.params | \
  $WGRIB2 -i ${COMOUT}/${dafs_ifi} -GRIB ${COMOUT}/${fname2}

  #-- icesev
  
  $WGRIB2 ${COMOUT}/${dafs_ifi} -s | grep -E ":ICESEV:|parm=37:"  | grep -F -f ${FIXdafs}/prdgen/dafs.ifi.sub304m.params | \
  # $WGRIB2 ${COMOUT}/${dafs_ifi} -s | grep ":var discipline=0 master_table=2 parmcat=19 parm=37:" | grep -F -f ${PARMdafs}/dafs.ifi.sub304m.params | \
  $WGRIB2 -i ${COMOUT}/${dafs_ifi} -GRIB ${COMOUT}/${fname3}

  #================================================================
  #-- add WMO header only at certain forcast hour
  
  parm_dir=${PARMdafs}/wmo

  #-- remove the leading 0"
  ifhr=$(expr $fhr + 0)

  if [ $ifhr = 1 -o  $ifhr = 2 -o  $ifhr = 3 -o  $ifhr = 6 -o  $ifhr = 9 -o  $ifhr = 12 -o  $ifhr = 15 -o  $ifhr = 18 ]; then

     #-- icprb

     parmfile=${parm_dir}/grib2.dafs.ifi.icprb.${fhr}      # parm file w/ header info
     infile=${COMOUT}/${fname1}
     outfile=${COMOUT}/wmo/grib2.dafs.t${cyc}z.ifi.icp.3km.${domain}.f${fhr}

     export FORT11=${infile}             # input file 
     export FORT12=                      # optional index file
     export FORT51=${outfile}            # output file w/ headers

     tocgrib2 < $parmfile 1>outfile.icprb.f${fhr}.$$

     #-- sipd
  
     parmfile=${parm_dir}/grib2.dafs.ifi.sipd.${fhr}      # parm file w/ header info
     infile=${COMOUT}/${fname2}
     outfile=${COMOUT}/wmo/grib2.dafs.t${cyc}z.ifi.sld.3km.${domain}.f${fhr}

     export FORT11=${infile}             # input file 
     export FORT12=                      # optional index file
     export FORT51=${outfile}            # output file w/ headers

     tocgrib2 < $parmfile 1>outfile.sipd.f${fhr}.$$

     #-- icesev

     parmfile=${parm_dir}/grib2.dafs.ifi.icesev.${fhr}      # parm file w/ header info
     infile=${COMOUT}/${fname3}
     outfile=${COMOUT}/wmo/grib2.dafs.t${cyc}z.ifi.sev.3km.${domain}.f${fhr}

     export FORT11=${infile}               # input file 
     export FORT12=                        # optional index file
     export FORT51=${outfile}              # output file w/ headers

     tocgrib2 < $parmfile 1>outfile.icesev.f${fhr}.$$

  fi
