#!/bin/bash

set -eu
set -x
# Get the root of the cloned DAFS directory
readonly DIR_ROOT=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}")")/../.." && pwd -P)
PDYcyc=${1}
export cyc=`echo ${PDYcyc} | cut -c9-10`

sourceroot=/lfs/h2/emc/ptmp/hsin-mu.lin/hrrr_tmp
targetroot=/lfs/h2/emc/ptmp/yali.mao/hrrr_tmp/nwges/hrrrges_sfc
rm -rf $targetroot

# alaska
sourcedir=$sourceroot/hrrr_alaska_fcst_prod_$cyc
# conus
sourcedir=$sourceroot/hrrr_conus_fcst_prod_$cyc

domains="alaska conus"

for domain in $domains ; do
    sourcedir=$sourceroot/hrrr_${domain}_fcst_prod_$cyc
    targetdir=$targetroot/$domain
    mkdir -p $targetdir
    if [ $domain = 'conus' ] ; then
	suffix="_"
    elif [ $domain = 'alaska' ] ; then
	suffix="ak_"
    fi
    for (( ifhr=1; ifhr<=18; ifhr++ )); do
	fhr=$(printf "%03d" $ifhr)

	VDATE=$($NDATE $ifhr $PDYcyc)
	export YY=`echo ${VDATE} | cut -c1-4`
	export MM=`echo ${VDATE} | cut -c5-6`
	export DD=`echo ${VDATE} | cut -c7-8`
	export HH=`echo ${VDATE} | cut -c9-10`

	sourfile="wrfout_d01_${YY}-${MM}-${DD}_${HH}_00_00"
	targetfile="hrrr${suffix}${PDYcyc}f${fhr}"
	ln -s $sourcedir/$sourfile $targetdir/$targetfile
    done
done

