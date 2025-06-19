#!/bin/bash
#

set -x

dafs_ifi=$1
dafs_gtg=$2

g130file_ifi=dafs.t${cyc}z.ifi.13km.conus.f${fhr}.grib2
g130file_gtg=dafs.t${cyc}z.gtg.13km.conus.f${fhr}.grib2

# ---- Get grib data at certain record # ----------------------
#
#  upscale to grid 130 for FAA
#  subset IFI for each variable at every 304 m & separate files 
#

#--- Grid 130 for the GTG & ICING process
grid_specs_130="lambert:265:25.000000 233.862000:451:13545.000000 16.281000:337:13545.000000"

mkdir -p ${COMOUT}/wmo

#---------------------------------------------------------------
#-- upscaling to G130 from 3km data

# -- IFI --
  $WGRIB2 ${COMOUT}/${dafs_ifi} -set_bitmap 1 -set_grib_type c3 \
     -new_grid_winds grid -new_grid_vectors "UGRD:VGRD:USTM:VSTM" \
     -new_grid_interpolation neighbor \
     -new_grid ${grid_specs_130} ${COMOUT}/${g130file_ifi}

#-- GTG --
  $WGRIB2 ${COMOUT}/${dafs_gtg} -set_bitmap 1 -set_grib_type c3 \
     -new_grid_winds grid -new_grid_vectors "UGRD:VGRD:USTM:VSTM" \
     -new_grid_interpolation bilinear \
     -new_grid ${grid_specs_130} ${COMOUT}/${g130file_gtg}
  
  
#--------------------------------------------------------------- 
#-- process IFI upscaling data 

  domain="conus"
  fname1="${RUN}.t${cyc}z.ifi.icp.13km.${domain}.f${fhr}.grib2"
  fname2="${RUN}.t${cyc}z.ifi.sld.13km.${domain}.f${fhr}.grib2"
  fname3="${RUN}.t${cyc}z.ifi.sev.13km.${domain}.f${fhr}.grib2"

  #-- subset IFI data at every 304 m & separate files

  #-- ICPRB

  $WGRIB2 ${COMOUT}/${g130file_ifi} -s | grep ":ICPRB:" | grep -F -f ${FIXdafs}/prdgen/dafs.ifi.sub304m.params | \
  $WGRIB2 -i ${COMOUT}/${g130file_ifi} -GRIB ${COMOUT}/${fname1}

  #-- sipd
  
  $WGRIB2 ${COMOUT}/${g130file_ifi} -s | grep ":SIPD:"  | grep -F -f ${FIXdafs}/prdgen/dafs.ifi.sub304m.params | \
  $WGRIB2 -i ${COMOUT}/${g130file_ifi} -GRIB ${COMOUT}/${fname2}

  #-- icesev
  
  $WGRIB2 ${COMOUT}/${g130file_ifi} -s | grep -E ":ICESEV:|parm=37:"  | grep -F -f ${FIXdafs}/prdgen/dafs.ifi.sub304m.params | \
  # $WGRIB2 ${COMOUT}/${g130file_ifi} -s | grep ":var discipline=0 master_table=2 parmcat=19 parm=37:" | grep -F -f ${FIXdafs}/prdgen/dafs.ifi.sub304m.params | \
  $WGRIB2 -i ${COMOUT}/${g130file_ifi} -GRIB ${COMOUT}/${fname3}

  #================================================================
  #-- add WMO header only at certain forcast hour

  parm_dir=${PARMdafs}/wmo

  #-- remove the leading 0"
  ifhr=$(expr $fhr + 0)

  if [ $ifhr = 1 -o  $ifhr = 2 -o  $ifhr = 3 -o  $ifhr = 6 -o  $ifhr = 9 -o  $ifhr = 12 -o  $ifhr = 15 -o  $ifhr = 18 ]; then   
  
     #-- icprb

     parmfile=${parm_dir}/grib2.dafs.ifi.icprb.${fhr}      # parm file w/ header info
     infile=${COMOUT}/${fname1}
     outfile=${COMOUT}/wmo/grib2.dafs.t${cyc}z.ifi.icp.13km.${domain}.f${fhr}

     export FORT11=${infile}             # input file 
     export FORT12=                      # optional index file
     export FORT51=${outfile}            # output file w/ headers

     tocgrib2 < $parmfile 1>outfile.icprb.f${fhr}.$$

     #-- sipd
  
     parmfile=${parm_dir}/grib2.dafs.ifi.sipd.${fhr}      # parm file w/ header info
     infile=${COMOUT}/${fname2}
     outfile=${COMOUT}/wmo/grib2.dafs.t${cyc}z.ifi.sld.13km.${domain}.f${fhr}

     export FORT11=${infile}             # input file 
     export FORT12=                      # optional index file
     export FORT51=${outfile}            # output file w/ headers

     tocgrib2 < $parmfile 1>outfile.sipd.f${fhr}.$$

     #-- icesev

     parmfile=${parm_dir}/grib2.dafs.ifi.icesev.${fhr}      # parm file w/ header info
     infile=${COMOUT}/${fname3}
     outfile=${COMOUT}/wmo/grib2.dafs.t${cyc}z.ifi.sev.13km.${domain}.f${fhr}

     export FORT11=${infile}               # input file 
     export FORT12=                        # optional index file
     export FORT51=${outfile}              # output file w/ headers

     tocgrib2 < $parmfile 1>outfile.icesev.f${fhr}.$$

  fi
