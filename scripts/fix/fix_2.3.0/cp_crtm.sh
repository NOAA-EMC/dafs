#! /bin/sh

FIXCRTM=/usrx/local/nceplibs/dev/NCEPLIBS/src/crtm_v2.3.0/fix

for what in 'Aerosol' 'Cloud' ; do
   cp "$FIXCRTM/${what}Coeff.bin" .
done

cp $FIXCRTM/NPOESS*EmisCoeff.bin .
cp $FIXCRTM/Nalli.IRwater.EmisCoeff.bin .
cp $FIXCRTM/FASTEM6.MWwater.EmisCoeff.bin .

for what in "amsre_aqua" "imgr_g11" "imgr_g12" "imgr_g13" \
    "imgr_g15" "imgr_mt1r" "imgr_mt2" "seviri_m10" \
    "ssmi_f13" "ssmi_f14" "ssmi_f15" "ssmis_f16" \
    "ssmis_f17" "ssmis_f18" "ssmis_f19" "ssmis_f20" \
    "tmi_trmm" "v.seviri_m10" "imgr_insat3d" "abi_gr" "ahi_himawari8" \
    ; do
    cp "$FIXCRTM/$what.TauCoeff.bin" .
    cp "$FIXCRTM/$what.SpcCoeff.bin" .
done
