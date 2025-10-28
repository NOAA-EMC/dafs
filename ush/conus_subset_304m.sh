#!/bin/bash
#
#######################################################################
#  UTILITY SCRIPT NAME : conus_subset_304m.sh
#
#  Abstract:  This script does the new maping (grid130) to IFI AND GTG & 
#  add wmo header to new IFI file 
#  1. upscale to grid 130 from the original 3km resolution, then
#  2. subset each icing variable in the CONUS grid130 IFI file at  
#  every 304m from the surface as defined in file "dafs.ifi.sub304m.params"
#  then add the WMO header to each new sebsetted file that containn only one
#  icing variable
# 3. Excluding EDPARM and add WMO headers to CATEDR, MWTURB, CITEDR, MXEDPRM(2D)
#
#  History:  08/16/2024 - initial version
#            10/28/2025 - Add WMO headers to 13km CONUS GTG
#####################################################################
set -x

var=$1 #ifi/gtg
dafs_3km=${NET}.t${cyc}z.${var}.3km.conus.f${fhr}.grib2
g130file=${NET}.t${cyc}z.${var}.13km.conus.f${fhr}.grib2

domain="conus"

# ---- Get grib data at certain record # ----------------------
#
#  upscale to grid 130 for FAA
#  subset IFI for each variable at every 304 m & separate files 
#

#--- Grid 130 for the GTG & ICING process
grid_specs_130="lambert:265:25.000000 233.862000:451:13545.000000 16.281000:337:13545.000000"

#---------------------------------------------------------------
#-- upscaling to G130 from 3km data

  $WGRIB2 ${dafs_3km} -set_bitmap 1 -set_grib_type c3 \
     -new_grid_winds grid -new_grid_vectors "UGRD:VGRD:USTM:VSTM" \
     -new_grid_interpolation neighbor \
     -new_grid ${grid_specs_130} ${g130file}

# Send data to COM
 if [[ "${SENDCOM}" == "YES" ]]; then
    cpfs "${g130file}" "${COMOUT}/${g130file}"
 fi

# Alert via DBN
if [[ "${SENDDBN}" == "YES" ]]; then
    "${DBNROOT}/bin/dbn_alert" MODEL DAFS_IFI_13km_CONUS_GB2 "${job}" "${COMOUT}/${g130file}"
fi

#--------------------------------------------------------------- 
#-- Add WMO headers to IFI upscaled data

parm_dir=${PARMdafs}/wmo
mkdir -p ${COMOUT}/wmo

# For WMO data, choose complex3 and no bitmap to decrease the file size
$WGRIB2 ${g130file} -set_bitmap 0 -set_grib_type c3 -grib_out ${g130file}.nobitmap
mv ${g130file}.nobitmap ${g130file}

if [[ $var == "ifi" ]] ; then
  fname1="${NET}.t${cyc}z.ifi.icp.13km.${domain}.f${fhr}.grib2"
  fname2="${NET}.t${cyc}z.ifi.sld.13km.${domain}.f${fhr}.grib2"
  fname3="${NET}.t${cyc}z.ifi.sev.13km.${domain}.f${fhr}.grib2"

  #-- subset IFI data at every 304 m & separate files

  cpreq ${FIXdafs}/prdgen/dafs.ifi.sub304m.params .


  #-- ICPRB

  $WGRIB2 ${g130file} -s | grep ":ICPRB:" | grep -F -f dafs.ifi.sub304m.params | \
  $WGRIB2 -i ${g130file} -GRIB ${fname1}

  #-- sipd
  
  $WGRIB2 ${g130file} -s | grep ":SIPD:"  | grep -F -f dafs.ifi.sub304m.params | \
  $WGRIB2 -i ${g130file} -GRIB ${fname2}

  #-- icesev
  
  $WGRIB2 ${g130file} -s | grep -E ":ICESEV:|parm=37:"  | grep -F -f dafs.ifi.sub304m.params | \
  $WGRIB2 -i ${g130file} -GRIB ${fname3}

  #-- remove the leading 0"
  ifhr=$(expr $fhr + 0)

  # As in DAFS implementation, public CONUS IFI icing will be disseminated hourly products
  #  if [ $ifhr = 1 -o  $ifhr = 2 -o  $ifhr = 3 -o  $ifhr = 6 -o  $ifhr = 9 -o  $ifhr = 12 -o  $ifhr = 15 -o  $ifhr = 18 ]; then   

     export pgm="${TOCGRIB2}"
      
     #-- icprb

     parmfile=grib2.dafs.ifi.icprb.${fhr}      # parm file w/ header info
     infile="${fname1}"
     wmofile=grib2.dafs.t${cyc}z.ifi.icp.13km.${domain}.f${fhr}

     cpreq ${parm_dir}/${parmfile} .

     . prep_step
     export FORT11=${infile}             # input file 
     export FORT12=                      # optional index file
     export FORT51=${wmofile}            # output file w/ headers

     ${TOCGRIB2} < $parmfile 1>wmofile.icprb.f${fhr}.$$

     export err=$?
     err_chk

     # Check if TOCGRIB2 succeeded in creating the output file
     if [[ ! -f "${FORT51}" ]]; then
        err_exit "FATAL ERROR: '${pgm}' failed to create '${FORT51}', ABORT!"
     fi

     # Send data to COM
     if [[ "${SENDCOM}" == "YES" ]]; then
        cpfs ${wmofile} ${COMOUT}/wmo/.
     fi

     if [[ "${SENDDBN_NTC}" == "YES" ]]; then
	 "${DBNROOT}/bin/dbn_alert" GRIB_LOW dafs "${job}" "${COMOUT}/wmo/${wmofile}"
     fi

     #-- sipd
  
     parmfile=grib2.dafs.ifi.sipd.${fhr}      # parm file w/ header info
     infile="${fname2}"
     wmofile=grib2.dafs.t${cyc}z.ifi.sld.13km.${domain}.f${fhr}

     cpreq ${parm_dir}/${parmfile} .

     . prep_step
     export FORT11=${infile}             # input file 
     export FORT12=                      # optional index file
     export FORT51=${wmofile}            # output file w/ headers

     ${TOCGRIB2} < $parmfile 1>wmofile.sipd.f${fhr}.$$

     export err=$?
     err_chk

     # Check if TOCGRIB2 succeeded in creating the output file
     if [[ ! -f "${FORT51}" ]]; then
        err_exit "FATAL ERROR: '${pgm}' failed to create '${FORT51}', ABORT!"
     fi

     # Send data to COM
     if [[ "${SENDCOM}" == "YES" ]]; then
        cpfs ${wmofile} ${COMOUT}/wmo/.
     fi

     if [[ "${SENDDBN_NTC}" == "YES" ]]; then
	 "${DBNROOT}/bin/dbn_alert" GRIB_LOW dafs "${job}" "${COMOUT}/wmo/${wmofile}"
     fi

     #-- icesev

     parmfile=grib2.dafs.ifi.icesev.${fhr}      # parm file w/ header info
     infile="${fname3}"
     wmofile=grib2.dafs.t${cyc}z.ifi.sev.13km.${domain}.f${fhr}

     cpreq ${parm_dir}/${parmfile} .

     . prep_step
     export FORT11=${infile}               # input file 
     export FORT12=                        # optional index file
     export FORT51=${wmofile}              # output file w/ headers

     ${TOCGRIB2} < $parmfile 1>wmofile.icesev.f${fhr}.$$

     export err=$?
     err_chk

     # Check if TOCGRIB2 succeeded in creating the output file
     if [[ ! -f "${FORT51}" ]]; then
        err_exit "FATAL ERROR: '${pgm}' failed to create '${FORT51}', ABORT!"
     fi

     # Send data to COM
     if [[ "${SENDCOM}" == "YES" ]]; then
        cpfs ${wmofile} ${COMOUT}/wmo/.
     fi

     if [[ "${SENDDBN_NTC}" == "YES" ]]; then
	 "${DBNROOT}/bin/dbn_alert" GRIB_LOW dafs "${job}" "${COMOUT}/wmo/${wmofile}"
     fi
  # fi
fi

#---------------------------------------------------------------
#-- Add WMO headers to GTG upscaled data
if [[ $var == "gtg" ]] ; then
    if [[ "000 001 002 003 006 009 012 015 018" =~ $fhr ]] ; then
	file_selected="${NET}.t${cyc}z.gtg.selected.13km.${domain}.f${fhr}.grib2"
	$WGRIB2 ${g130file}  | grep -v ":EDPARM:" | $WGRIB2 -i ${g130file} -GRIB ${file_selected}

	export pgm="${TOCGRIB2}"

	parmfile=grib2.dafs.gtg.${fhr}
	wmofile=grib2.dafs.t${cyc}z.gtg.13km.${domain}.f${fhr}

	cpreq ${parm_dir}/${parmfile} .

	. prep_step
	export FORT11="${file_selected}"    # input file
	export FORT12=                      # optional index file
	export FORT51=${wmofile}            # output file w/ headers
    
	${TOCGRIB2} < $parmfile 1>wmofile.gtg.f${fhr}.$$

	export err=$?
	err_chk

	# Check if TOCGRIB2 succeeded in creating the output file
	if [[ ! -f "${FORT51}" ]]; then
            err_exit "FATAL ERROR: '${pgm}' failed to create '${FORT51}', ABORT!"
	fi

	# Send data to COMOUT/wmo
	if [[ "${SENDCOM}" == "YES" ]]; then
            cpfs ${wmofile} ${COMOUT}/wmo/.
	fi

	if [[ "${SENDDBN_NTC}" == "YES" ]]; then
            "${DBNROOT}/bin/dbn_alert" GRIB_LOW dafs "${job}" "${COMOUT}/wmo/${wmofile}"
	fi
    fi
fi

    
