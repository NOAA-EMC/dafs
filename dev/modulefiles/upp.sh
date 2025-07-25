#!/bin/bash
# modulefile for UPP run
set -x

module load intel/${intel_ver}
module load PrgEnv-intel/${PrgEnvintel_ver}
module load craype/$craype_ver

# To access mpiexec
module load cray-pals/$craypals_ver

module load libjpeg/$libjpeg_ver
module load prod_util/$prod_util_ver
module load prod_envir/$prod_envir_ver
module load grib_util/$grib_util_ver
module load wgrib2/$wgrib2_ver

module load hdf5/$hdf5_ver
module load netcdf/$netcdf_ver
module load cray-mpich/$craympich_ver
module load g2tmpl/$g2tmpl_ver
