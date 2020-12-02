#!/bin/bash -l
#SBATCH --export=NONE
#SBATCH -p workq
#SBATCH --time=5:00:00
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
    flagantennae ${obsnum}.ms ${flagged}
fi

## run aoflagger
aoflagger ${obsnum}.ms

## calibrate
calibrate -absmem 120 -m ../../models/model-${model}*withalpha.txt -minuv 150 -ch 4 -applybeam -mwa-path /pawsey/mwa ${obsnum}.ms round1.bin

## applysolution
applysolutions ${obsnum}.ms round1.bin

## flag the new column
aoflagger -column CORRECTED_DATA ${obsnum}.ms

## image for selfcal
wsclean -name selfcal1 -size 1400 1400 -scale 1amin -niter 10000 -mgain 0.8 -weight natural -auto-threshold 1.5 -quiet ${obsnum}.ms

## selfcal
calibrate -absmem 120 -minuv 150 -ch 4 -applybeam -mwa-path /pawsey/mwa -quiet ${obsnum}.ms round2.bin

applysolutions ${obsnum}.ms round2.bin
wsclean -name selfcal2 -size 1400 1400 -scale 1amin -niter 10000 -mgain 0.8 -weight natural -auto-threshold 1.5 -quiet ${obsnum}.ms



## interpolate for flagged freq
cp /home/sprabu/customPython/interpolate .
myPython ./interpolate --inputFile round2.bin --outputFile ${obsnum}.bin


end=`date +%s`
runtime=$((end-start))
echo "the job run time ${runtime}"


}

