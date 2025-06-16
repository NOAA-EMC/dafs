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

  fname1="${RUN}.t${cyc}z.ifi.icp.${domain}.f${fhr}.grib2"
  fname2="${RUN}.t${cyc}z.ifi.sld.${domain}.f${fhr}.grib2"
  fname3="${RUN}.t${cyc}z.ifi.sev.${domain}.f${fhr}.grib2"

  #-- ICPRB
  
  $WGRIB2 ${COMOUT}/${dafs_ifi} -s | grep ":ICPRB:" | grep -F -f ${PARMdafs}/rrfs.ifi.sub304m.params | \
  $WGRIB2 -i ${COMOUT}/${dafs_ifi} -GRIB ${COMOUT}/${fname1}

  #-- sipd
  
  $WGRIB2 ${COMOUT}/${dafs_ifi} -s | grep ":SIPD:"  | grep -F -f ${PARMdafs}/rrfs.ifi.sub304m.params | \
  $WGRIB2 -i ${COMOUT}/${dafs_ifi} -GRIB ${COMOUT}/${fname2}

  #-- icesev
  
  $WGRIB2 ${COMOUT}/${dafs_ifi} -s | grep -E ":ICESEV:|parm=37:"  | grep -F -f ${PARMdafs}/rrfs.ifi.sub304m.params | \
  # $WGRIB2 ${COMOUT}/${dafs_ifi} -s | grep ":var discipline=0 master_table=2 parmcat=19 parm=37:" | grep -F -f ${PARMdafs}/rrfs.ifi.sub304m.params | \
  $WGRIB2 -i ${COMOUT}/${dafs_ifi} -GRIB ${COMOUT}/${fname3}

  #================================================================
  #-- add WMO header
  
  parm_dir=${PARMdafs}/wmo

  #-- icprb

  parmfile=${parm_dir}/grib2.rrfs.ifi.icprb.${fhr}      # parm file w/ header info
  infile=${COMOUT}/${fname1}
  outfile=${COMOUT}/wmo/grib2.dafs.t${cyc}z.ifi.icp.${domain}.f${fhr}

  export FORT11=${infile}             # input file 
  export FORT12=                      # optional index file
  export FORT51=${outfile}            # output file w/ headers

  tocgrib2 < $parmfile 1>outfile.icprb.f${fhr}.$$

  #-- sipd
  
  parmfile=${parm_dir}/grib2.rrfs.ifi.sipd.${fhr}      # parm file w/ header info
  infile=${COMOUT}/${fname2}
  outfile=${COMOUT}/wmo/grib2.dafs.t${cyc}z.ifi.sld.${domain}.f${fhr}

  export FORT11=${infile}             # input file 
  export FORT12=                      # optional index file
  export FORT51=${outfile}            # output file w/ headers

  tocgrib2 < $parmfile 1>outfile.sipd.f${fhr}.$$

  #-- icesev

  parmfile=${parm_dir}/grib2.rrfs.ifi.icesev.${fhr}      # parm file w/ header info
  infile=${COMOUT}/${fname3}
  outfile=${COMOUT}/wmo/grib2.dafs.t${cyc}z.ifi.sev.${domain}.f${fhr}

  export FORT11=${infile}               # input file 
  export FORT12=                        # optional index file
  export FORT51=${outfile}              # output file w/ headers

  tocgrib2 < $parmfile 1>outfile.icesev.f${fhr}.$$
