#!/bin/bash
#
#######################################################################
#  UTILITY SCRIPT NAME : conus_subset_ifi_304m.sh
#
#  Abstract:  This script does the new maping (grid130) to IFI AND GTG & 
#  add wmo header to new IFI file 
#  1. upscale to grid 130 from the original 3km resolution, then
#  2. subset each icing variable in the CONUS grid130 IFI file at  
#  every 304m from the surface as defined in file "dafs.ifi.sub304m.params"
#  then add the WMO header to each new sebsetted file that containn only one
#  icing variable
#
#  History:  08/16/2024
#              - initial version
#####################################################################
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

cd "${COMOUT}" || err_exit "FATAL ERROR: Could not 'cd ${COMOUT}'; ABORT!"
mkdir -p ${COMOUT}/wmo

#---------------------------------------------------------------
#-- upscaling to G130 from 3km data

# -- IFI --
  $WGRIB2 ${dafs_ifi} -set_bitmap 1 -set_grib_type c3 \
     -new_grid_winds grid -new_grid_vectors "UGRD:VGRD:USTM:VSTM" \
     -new_grid_interpolation neighbor \
     -new_grid ${grid_specs_130} ${g130file_ifi}

#-- GTG --
  $WGRIB2 ${dafs_gtg} -set_bitmap 1 -set_grib_type c3 \
     -new_grid_winds grid -new_grid_vectors "UGRD:VGRD:USTM:VSTM" \
     -new_grid_interpolation bilinear \
     -new_grid ${grid_specs_130} ${g130file_gtg}
  
  
#--------------------------------------------------------------- 
#-- process IFI upscaling data 

  domain="conus"
  fname1="${RUN}.t${cyc}z.ifi.icp.13km.${domain}.f${fhr}.grib2"
  fname2="${RUN}.t${cyc}z.ifi.sld.13km.${domain}.f${fhr}.grib2"
  fname3="${RUN}.t${cyc}z.ifi.sev.13km.${domain}.f${fhr}.grib2"

  #-- subset IFI data at every 304 m & separate files

  cpreq ${FIXdafs}/prdgen/dafs.ifi.sub304m.params .

  #-- ICPRB

  $WGRIB2 ${g130file_ifi} -s | grep ":ICPRB:" | grep -F -f dafs.ifi.sub304m.params | \
  $WGRIB2 -i ${g130file_ifi} -GRIB ${fname1}
  # $WGRIB2 -i ${COMOUT}/${g130file_ifi} -GRIB ${COMOUT}/${fname1}

  #-- sipd
  
  $WGRIB2 ${g130file_ifi} -s | grep ":SIPD:"  | grep -F -f dafs.ifi.sub304m.params | \
  $WGRIB2 ${g130file_ifi} -GRIB ${fname2}
  # $WGRIB2 -i ${COMOUT}/${g130file_ifi} -GRIB ${COMOUT}/${fname2}

  #-- icesev
  
  $WGRIB2 ${g130file_ifi} -s | grep -E ":ICESEV:|parm=37:"  | grep -F -f dafs.ifi.sub304m.params | \
  # $WGRIB2 ${COMOUT}/${g130file_ifi} -s | grep ":var discipline=0 master_table=2 parmcat=19 parm=37:" | grep -F -f ${FIXdafs}/prdgen/dafs.ifi.sub304m.params | \
  $WGRIB2 -i ${g130file_ifi} -GRIB ${fname3}
  # $WGRIB2 -i ${COMOUT}/${g130file_ifi} -GRIB ${COMOUT}/${fname3}

  #================================================================
  #-- add WMO header only at certain forcast hour

  parm_dir=${PARMdafs}/wmo

  #-- remove the leading 0"
  ifhr=$(expr $fhr + 0)

  if [ $ifhr = 1 -o  $ifhr = 2 -o  $ifhr = 3 -o  $ifhr = 6 -o  $ifhr = 9 -o  $ifhr = 12 -o  $ifhr = 15 -o  $ifhr = 18 ]; then   
  
     #-- icprb

     parmfile=grib2.dafs.ifi.icprb.${fhr}      # parm file w/ header info
     infile=${fname1}
     # infile=${COMOUT}/${fname1}
     outfile=grib2.dafs.t${cyc}z.ifi.icp.13km.${domain}.f${fhr}

     cpreq ${parm_dir}/${parmfile} .

     export FORT11=${infile}             # input file 
     export FORT12=                      # optional index file
     export FORT51=${outfile}            # output file w/ headers

     ${TOCGRIB2} < $parmfile 1>outfile.icprb.f${fhr}.$$

     export err=$?
     err_chk

     # Check if TOCGRIB2 succeeded in creating the output file
     if [[ ! -f "${FORT51}" ]]; then
        err_exit "FATAL ERROR: '${pgm}' failed to create '${FORT51}', ABORT!"
     fi

     # Send data to COM
     if [[ "${SENDCOM}" == "YES" ]]; then
        cpfs ${outfile} ${COMOUT}/wmo
     fi

     #-- sipd
  
     parmfile=grib2.dafs.ifi.sipd.${fhr}      # parm file w/ header info
     infile=${fname2}
     # infile=${COMOUT}/${fname2}
     outfile=grib2.dafs.t${cyc}z.ifi.sld.13km.${domain}.f${fhr}

     cpreq ${parm_dir}/${parmfile} .

     export FORT11=${infile}             # input file 
     export FORT12=                      # optional index file
     export FORT51=${outfile}            # output file w/ headers

     ${TOCGRIB2} < $parmfile 1>outfile.sipd.f${fhr}.$$

     export err=$?
     err_chk

     # Check if TOCGRIB2 succeeded in creating the output file
     if [[ ! -f "${FORT51}" ]]; then
        err_exit "FATAL ERROR: '${pgm}' failed to create '${FORT51}', ABORT!"
     fi

     # Send data to COM
     if [[ "${SENDCOM}" == "YES" ]]; then
        cpfs ${outfile} ${COMOUT}/wmo
     fi

     #-- icesev

     parmfile=grib2.dafs.ifi.icesev.${fhr}      # parm file w/ header info
     infile=${fname3}
     # infile=${COMOUT}/${fname3}
     outfile=grib2.dafs.t${cyc}z.ifi.sev.13km.${domain}.f${fhr}

     cpreq ${parm_dir}/${parmfile} .

     export FORT11=${infile}               # input file 
     export FORT12=                        # optional index file
     export FORT51=${outfile}              # output file w/ headers

     ${TOCGRIB2} < $parmfile 1>outfile.icesev.f${fhr}.$$

     export err=$?
     err_chk

     # Check if TOCGRIB2 succeeded in creating the output file
     if [[ ! -f "${FORT51}" ]]; then
        err_exit "FATAL ERROR: '${pgm}' failed to create '${FORT51}', ABORT!"
     fi

     # Send data to COM
     if [[ "${SENDCOM}" == "YES" ]]; then
        cpfs ${outfile} ${COMOUT}/wmo
     fi

  fi
