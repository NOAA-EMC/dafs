#!/bin/bash 
set -x

###########################################################################
#  UTILITY SCRIPT NAME :  exdafs_upp_alaska.sh
#         DATE WRITTEN :  06/15/2025
#
#  Abstract:  This script runs the offline UPP based on HRRR Alaska
#             model output and creates Alaska Icing grib2 file
#
#  History:  06/15/2025
#               - initial version, for DAFS v1.0.0
###########################################################################
POSTGRB2TBL=${POSTGRB2TBL:-"${g2tmpl_ROOT}/share/params_grib2_tbl_new"}
APRUN=${APRUN:-"mpiexec -l -n 48 -ppn 12 --cpu-bind core --depth 2"}

cd "${DATA}" || err_exit "FATAL ERROR: Could not 'cd ${DATA}'; ABORT!"

VDATE=$(${NDATE} +${fhr} ${PDY}${cyc})
hrrrinput="hrrrak_${PDY}${cyc}f${fhr}"
# Create the itag file
rm -f itag
cat >itag <<EOF
&model_inputs
fileName="$hrrrinput"
IOFORM="netcdf"
grib="grib2"
DateStr="${VDATE:0:4}-${VDATE:4:2}-${VDATE:6:2}_${VDATE:8:2}:00:00"
MODELNAME="RAPR"
SUBMODELNAME="RAPR"
/
&NAMPGB
KPO=47,PO=2.,5.,7.,10.,20.,30.,50.,70.,75.,100.,125.,150.,175.,200.,225.,250.,275.,300.,325.,350.,375.,400.,425.,450.,475.,500.,525.,550.,575.,600.,625.,650.,675.,700.,725.,750.,775.,800.,825.,850.,875.,900.,925.,950.,975.,1000.,1013.2,gtg_on=.false.
/
EOF
cat itag

rm -f fort.*

# Copy required inputs to local directory
cpreq "$COMIN/$hrrrinput" .
cpreq "${POSTGRB2TBL}" .
cpreq "${PARMdafs}/upp/postxconfig-NT-hrrr_dafs.txt" ./postxconfig-NT.txt
#cpreq "${PARMdafs}/upp/gtg.input.hrrr" gtg.input.hrrr
#cpreq "${PARMdafs}/upp/gtg.config.hrrr" gtg.config.hrrr


# output file from UPP executable

fhr2d=$(printf "%02d" $((10#${fhr})))
export PGBOUT="IFIFIP.GrbF${fhr2d}"
export pgm="dafs_upp.x"

# Clean out any existing output files
. prep_step

${APRUN} ${EXECdafs}/${pgm} <itag >>${pgmout} 2>errfile
export err=$?
err_chk

# Check if UPP succeeded in creating the master file
if [[ ! -f "${PGBOUT}" ]]; then
    err_exit "FATAL ERROR: UPP failed to create '${PGBOUT}', ABORT!"
fi

# Change the data center from EMC to AWC, then copy dafs IFI file to COMOUT and index the file
dafs_ifi="${RUN}.t${cyc}z.ifi.3km.ak.f${fhr}.grib2"
if [[ "${SENDCOM}" == "YES" ]]; then
    ${WGRIB2} -set subcenter 8 ${PGBOUT} -grib ${COMOUT}/${dafs_ifi} 
    #  cpfs "${PGBOUT}" "${COMOUT}/${dafs_ifi}"
    ${WGRIB2} -s "${PGBOUT}" >"${COMOUT}/${dafs_ifi}.idx"
fi

###----- PRDGEN process and WMO header ----------------------
fhrx=$(expr $fhr + 0) #remove the leading 0
$USHdafs/ak_subset_ifi_304m.sh ${dafs_ifi}

echo "PROGRAM IS COMPLETE!!!!!"
date
