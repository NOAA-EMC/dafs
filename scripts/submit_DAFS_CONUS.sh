#!/bin/bash

#PBS -j oe
#PBS -N DAFS_conus
#PBS -l walltime=00:10:00
#PBS -q debug
#PBS -A GFS-DEV
#PBS -l place=vscatter,select=4:ncpus=72
#PBS -V
#PBS -l debug=true

cd $PBS_O_WORKDIR

set -x

# specify computation resource
export threads=1
export MP_LABELIO=yes
export OMP_NUM_THREADS=$threads

# keep proceeses off hyperthread cores
export OMP_PROC_BIND=true

export APRUN="mpiexec -l -n 144 -ppn 36 --cpu-bind core --depth 2"
# export APRUN="mpiexec -l -n 48 -ppn 24"

echo "starting time"
date

############################################
# Loading module
############################################

module reset
module load intel/19.1.3.304
module load PrgEnv-intel/8.1.0
module load craype/2.7.8
module load cray-mpich/8.1.7
module load cray-pals/1.0.12
module load hdf5/1.10.6
module load netcdf/4.7.4
module load libjpeg/9c
module load prod_util/2.0.8

module list

#--- specify your UPP directory
export gitdir=/lfs/h2/emc/physics/save/hsin-mu.lin/CIRA/DAFS/sorc/UPP
export POSTGPEXEC=${gitdir}/exec/upp.x

#--- specify forecast start time and hour for running your post job

export cdate=cdate_4_cycle
export fhr=fhr_4_cycle

yyyymmdd=${cdate:0:8}
cycle=${cdate:8:2}

NEWDATE=`${NDATE} +${fhr} $cdate`
export YY=`echo ${NEWDATE} | cut -c1-4`
export MM=`echo ${NEWDATE} | cut -c5-6`
export DD=`echo ${NEWDATE} | cut -c7-8`
export HH=`echo ${NEWDATE} | cut -c9-10`

#--- Input Data
export datain=/lfs/h1/ops/prod/com/hrrr/v4.1/nwges/hrrrges_sfc/conus

#--- Directory for All DAFS fcst
export datadir=/lfs/h2/emc/ptmp/$USER/dafs/v1.0/dafs.${yyyymmdd}/${cycle}/upp/conus
# export datadir=/lfs/h1/ops/prod/com/dafs/v1.0/dafs.${yyyymmdd}/${cycle}/upp/conus

#--- Directory 
export DAFS_FSCT=${datadir}
mkdir -p ${DAFS_FSCT}

#--- specify the running and output directory for each cycle
export rundir=/lfs/h2/emc/ptmp/$USER/DAFS_tmp
export DATA=$rundir/hrrr_${cdate}_f${fhr}

rm -rf $DATA; mkdir -p $DATA
cd $DATA

#--- execute main process

cat > itag <<EOF
&model_inputs
fileName='${datain}/hrrr_${cdate}f0${fhr}'
IOFORM='netcdf'
grib='grib2'
DateStr='${YY}-${MM}-${DD}_${HH}:00:00'
MODELNAME='RAPR'
SUBMODELNAME='RAPR'
/
&NAMPGB
KPO=47,PO=2.,5.,7.,10.,20.,30.,50.,70.,75.,100.,125.,150.,175.,200.,225.,250.,275.,300.,325.,350.,375.,400.,425.,450.,475.,500.,525.,550.,575.,600.,625.,650.,675.,700.,725.,750.,775.,800.,825.,850.,875.,900.,925.,950.,975.,1000.,1013.2,gtg_on=.true.
/
EOF
#FMIN

rm -f fort.*

###----- copy GTG_hrrr config file ----------------------

cp ${gitdir}/sorc/ncep_post.fd/post_gtg.fd/gtg.config.hrrr ./gtg.config.hrrr
cp ${gitdir}/sorc/ncep_post.fd/post_gtg.fd/gtg.input.hrrr ./gtg.input.hrrr

#--- copy fix data

cp ${gitdir}/../../scripts/fix/fix_2.3.0/*bin .
cp ${gitdir}/parm/params_grib2_tbl_new params_grib2_tbl_new
cp ${gitdir}/parm/postxconfig-NT-hrrr_dafs.txt postxconfig-NT.txt
cp ${gitdir}/fix/rap_micro_lookup.dat eta_micro_lookup.dat


${APRUN} ${POSTGPEXEC} < itag > outpost_hrrr_${NEWDATE}

mv IFIFIP.GrbF${fhr} dafs.t${cycle}z.ifi.conus.f0${fhr}.grib2
mv AVIATION.GrbF${fhr} dafs.t${cycle}z.gtg.conus.f0${fhr}.grib2
mv dafs.t* ${DAFS_FSCT}

echo "PROGRAM IS COMPLETE!!!!!"
date
