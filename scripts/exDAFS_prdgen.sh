#!/bin/bash


#-----------------------------------------------------------------------
#
# Get the cycle date and hour (in formats of yyyymmdd and hh, respectively)
# from cdate.
#
#-----------------------------------------------------------------------

yyyymmdd=${cdate:0:8}
hh=${cdate:8:2}
cyc=$hh

#-- Upscale & subset FAA requested information
    
# echo "$USHrrfs/rrfs_prdgen_faa_subpiece.sh $fhr $cyc $prslev $natlev $ififip $aviati ${COMOUT} &" >> $DATAprdgen/poescript_faa_${fhr}

${USHrrfs}/rrfs_prdgen_faa_subpiece.sh $fhr $cyc $prslev $natlev $ififip $aviati ${COMOUT} ${USHrrfs} ${FIXprdgen} ${PARMdir}



