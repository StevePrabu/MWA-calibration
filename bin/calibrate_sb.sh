#!/bin/bash -l
#SBATCH --export=NONE
#SBATCH -p workq
#SBATCH --time=10:00:00
#SBATCH --ntasks=28
#SBATCH --mem=124GB
#SBATCH -J calibration
#SBATCH --mail-type FAIL,TIME_LIMIT,TIME_LIMIT_90
#SBATCH --mail-user sirmcmissile47@gmail.com

start=`date +%s`
module load singularity
shopt -s expand_aliases
source /astro/mwasci/sprabu/aliases

set -x
{

obsnum=OBSNUM
base=BASE
model=
link=
datadir=${base}processing
cd ${datadir}

rm -r ${obsnum}
mkdir -p ${obsnum}
cd  ${obsnum}


while getopts 'm:l:' OPTION
do
    case "$OPTION" in
        m)
            model=${OPTARG}
            ;;
	l)
	    link=${OPTARG}
	    ;;
    esac
done


## download file
wget -O ${obsnum}_ms.zip --no-check-certificate "${link}"

unzip -n ${obsnum}_ms.zip




## flag bad tiles
cp /home/sprabu/customPython/getFlaggedTiles.py .
flagged=$(myPython ./getFlaggedTiles.py --metafits ${obsnum}.metafits)


if [[ ! -z ${flagged} ]]; then
    flagantennae ${obsnum}_068-083.ms ${flagged}
    flagantennae ${obsnum}_107-108.ms ${flagged}
    flagantennae ${obsnum}_112-114.ms ${flagged}
    flagantennae ${obsnum}_147-149.ms ${flagged}
fi



### run aoflagger
aoflagger ${obsnum}_068-083.ms
aoflagger ${obsnum}_107-108.ms
aoflagger ${obsnum}_112-114.ms
aoflagger ${obsnum}_147-149.ms




### calibrate
calibrate -absmem 120 -m ../../models/model-${model}*withalpha.txt -minuv 150 -ch 4 -applybeam -mwa-path /pawsey/mwa ${obsnum}_068-083.ms round1_band1.bin
calibrate -absmem 120 -m ../../models/model-${model}*withalpha.txt -minuv 150 -ch 4 -applybeam -mwa-path /pawsey/mwa ${obsnum}_107-108.ms round1_band2.bin
calibrate -absmem 120 -m ../../models/model-${model}*withalpha.txt -minuv 150 -ch 4 -applybeam -mwa-path /pawsey/mwa ${obsnum}_112-114.ms round1_band3.bin
calibrate -absmem 120 -m ../../models/model-${model}*withalpha.txt -minuv 150 -ch 4 -applybeam -mwa-path /pawsey/mwa ${obsnum}_147-149.ms round1_band4.bin



## applysolution
applysolutions ${obsnum}_068-083.ms round1_band1.bin
applysolutions ${obsnum}_107-108.ms round1_band2.bin
applysolutions ${obsnum}_112-114.ms round1_band3.bin
applysolutions ${obsnum}_147-149.ms round1_band4.bin



### flag the new column
aoflagger -column CORRECTED_DATA ${obsnum}_068-083.ms
aoflagger -column CORRECTED_DATA ${obsnum}_107-108.ms
aoflagger -column CORRECTED_DATA ${obsnum}_112-114.ms
aoflagger -column CORRECTED_DATA ${obsnum}_147-149.ms




### image for selfcal
wsclean -name selfcal1-band1 -size 1400 1400 -scale 1amin -niter 10000 -mgain 0.8 -weight natural -auto-threshold 1.5 -quiet ${obsnum}_068-083.ms
wsclean -name selfcal1-band2 -size 1400 1400 -scale 1amin -niter 10000 -mgain 0.8 -weight natural -auto-threshold 1.5 -quiet ${obsnum}_107-108.ms
wsclean -name selfcal1-band3 -size 1400 1400 -scale 1amin -niter 10000 -mgain 0.8 -weight natural -auto-threshold 1.5 -quiet ${obsnum}_112-114.ms
wsclean -name selfcal1-band4 -size 1400 1400 -scale 1amin -niter 10000 -mgain 0.8 -weight natural -auto-threshold 1.5 -quiet ${obsnum}_147-149.ms


### selfcal
calibrate -absmem 120 -minuv 150 -ch 4 -applybeam -mwa-path /pawsey/mwa -quiet ${obsnum}_068-083.ms round2_band1.bin
calibrate -absmem 120 -minuv 150 -ch 4 -applybeam -mwa-path /pawsey/mwa -quiet ${obsnum}_107-108.ms round2_band2.bin
calibrate -absmem 120 -minuv 150 -ch 4 -applybeam -mwa-path /pawsey/mwa -quiet ${obsnum}_112-114.ms round2_band3.bin
calibrate -absmem 120 -minuv 150 -ch 4 -applybeam -mwa-path /pawsey/mwa -quiet ${obsnum}_147-149.ms round2_band4.bin


applysolutions ${obsnum}_068-083.ms round2_band1.bin
applysolutions ${obsnum}_107-108.ms round2_band2.bin
applysolutions ${obsnum}_112-114.ms round2_band3.bin
applysolutions ${obsnum}_147-149.ms round2_band4.bin

wsclean -name selfcal2-band1 -size 1400 1400 -scale 1amin -niter 10000 -mgain 0.8 -weight natural -auto-threshold 1.5 -quiet ${obsnum}_068-083.ms
wsclean -name selfcal2-band2 -size 1400 1400 -scale 1amin -niter 10000 -mgain 0.8 -weight natural -auto-threshold 1.5 -quiet ${obsnum}_107-108.ms
wsclean -name selfcal2-band3 -size 1400 1400 -scale 1amin -niter 10000 -mgain 0.8 -weight natural -auto-threshold 1.5 -quiet ${obsnum}_112-114.ms
wsclean -name selfcal2-band4 -size 1400 1400 -scale 1amin -niter 10000 -mgain 0.8 -weight natural -auto-threshold 1.5 -quiet ${obsnum}_147-149.ms


### interpolate for flagged freq
#cp /home/sprabu/customPython/interpolate .
#myPython ./interpolate --inputFile round2.bin --outputFile ${obsnum}.bin


end=`date +%s`
runtime=$((end-start))
echo "the job run time ${runtime}"


}

