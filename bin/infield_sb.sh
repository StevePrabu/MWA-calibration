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

#rm -r ${obsnum}
mkdir -p ${obsnum}
cd  ${obsnum}


while getopts 'l:' OPTION
do
    case "$OPTION" in
	l)
	    link=${OPTARG}
	    ;;
    esac
done


## download file
#wget -O ${obsnum}_ms.zip --no-check-certificate "${link}"

#unzip -n ${obsnum}_ms.zip


## create local gleam model (copied from /astro/mwasci/phancock/D0009/queue/infield_cal_1290513616.sh)
catfile=/astro/mwasci/phancock/D0009/external/GLEAM-X-pipeline/models/skymodel_walpha.fits
# import the tag and test_fail functions
. /astro/mwasci/phancock/D0009/bin/functions.sh
# setup the container mappings
. /astro/mwasci/phancock/D0009/bin/containers.sh

metafits="${obsnum}.metafits"
RA=$( ${Crfiseeker} gethead RA $metafits )
Dec=$( ${Crfiseeker} gethead DEC $metafits )
chan=$( ${Crfiseeker} gethead CENTCHAN $metafits )

solutions=${obsnum}_infield_solutions_initial.bin
radius="--radius=30"
if [[ ! -e "local_gleam_model.txt" ]]
then
    ${Cgleamx} crop_catalogue.py --ra=${RA} --dec=${Dec} ${radius} --minflux=1.0 --attenuate --metafits=${metafits} --catalogue=${catfile} --fluxcol=S_200
    ${Cgleamx} vo2model.py --catalogue=cropped_catalogue.fits --point --output=local_gleam_model.txt --racol=RAJ2000 --decol=DEJ2000 --acol=a --bcol=b --pacol=pa --fluxcol=S_200 --alphacol=alpha
fi


## flag bad tiles
cp /home/sprabu/customPython/getFlaggedTiles.py .
flagged=$(myPython ./getFlaggedTiles.py --metafits ${obsnum}.metafits)

b1name="068-079"
b2name="107-108"
b3name="112-114"
b4name="147-153"

if [[ ! -z ${flagged} ]]; then
    flagantennae ${obsnum}${b1name}.ms ${flagged}
    flagantennae ${obsnum}${b2name}.ms ${flagged}
    flagantennae ${obsnum}${b3name}.ms ${flagged}
    flagantennae ${obsnum}${b4name}.ms ${flagged}
fi



### run aoflagger
aoflagger ${obsnum}${b1name}.ms
aoflagger ${obsnum}${b2name}.ms
aoflagger ${obsnum}${b3name}.ms
aoflagger ${obsnum}${b4name}.ms




### calibrate
calibrate -absmem 120 -m local_gleam_model.txt -minuv 150 -ch 4 -applybeam -mwa-path /pawsey/mwa ${obsnum}068-079.ms round1_band1.bin
calibrate -absmem 120 -m local_gleam_model.txt -minuv 150 -ch 4 -applybeam -mwa-path /pawsey/mwa ${obsnum}107-108.ms round1_band2.bin
calibrate -absmem 120 -m local_gleam_model.txt -minuv 150 -ch 4 -applybeam -mwa-path /pawsey/mwa ${obsnum}112-114.ms round1_band3.bin
calibrate -absmem 120 -m local_gleam_model.txt -minuv 150 -ch 4 -applybeam -mwa-path /pawsey/mwa ${obsnum}147-153.ms round1_band4.bin



## applysolution
applysolutions ${obsnum}068-079.ms round1_band1.bin
applysolutions ${obsnum}107-108.ms round1_band2.bin
applysolutions ${obsnum}112-114.ms round1_band3.bin
applysolutions ${obsnum}147-153.ms round1_band4.bin



### flag the new column
aoflagger -column CORRECTED_DATA ${obsnum}068-079.ms
aoflagger -column CORRECTED_DATA ${obsnum}107-108.ms
aoflagger -column CORRECTED_DATA ${obsnum}112-114.ms
aoflagger -column CORRECTED_DATA ${obsnum}147-153.ms




### image for selfcal
wsclean -name selfcal1-band1 -size 1400 1400 -scale 1amin -niter 10000 -mgain 0.8 -weight natural -auto-threshold 1.5 -quiet ${obsnum}068-079.ms
wsclean -name selfcal1-band2 -size 1400 1400 -scale 1amin -niter 10000 -mgain 0.8 -weight natural -auto-threshold 1.5 -quiet ${obsnum}107-108.ms
wsclean -name selfcal1-band3 -size 1400 1400 -scale 1amin -niter 10000 -mgain 0.8 -weight natural -auto-threshold 1.5 -quiet ${obsnum}112-114.ms
wsclean -name selfcal1-band4 -size 1400 1400 -scale 1amin -niter 10000 -mgain 0.8 -weight natural -auto-threshold 1.5 -quiet ${obsnum}147-153.ms


### selfcal
calibrate -absmem 120 -minuv 150 -ch 4 -applybeam -mwa-path /pawsey/mwa -quiet ${obsnum}068-079.ms round2_band1.bin
calibrate -absmem 120 -minuv 150 -ch 4 -applybeam -mwa-path /pawsey/mwa -quiet ${obsnum}107-108.ms round2_band2.bin
calibrate -absmem 120 -minuv 150 -ch 4 -applybeam -mwa-path /pawsey/mwa -quiet ${obsnum}112-114.ms round2_band3.bin
calibrate -absmem 120 -minuv 150 -ch 4 -applybeam -mwa-path /pawsey/mwa -quiet ${obsnum}147-153.ms round2_band4.bin


applysolutions ${obsnum}068-079.ms round2_band1.bin
applysolutions ${obsnum}107-108.ms round2_band2.bin
applysolutions ${obsnum}112-114.ms round2_band3.bin
applysolutions ${obsnum}147-153.ms round2_band4.bin

wsclean -name selfcal2-band1 -size 1400 1400 -scale 1amin -niter 10000 -mgain 0.8 -weight natural -auto-threshold 1.5 -quiet ${obsnum}068-079.ms
wsclean -name selfcal2-band2 -size 1400 1400 -scale 1amin -niter 10000 -mgain 0.8 -weight natural -auto-threshold 1.5 -quiet ${obsnum}107-108.ms
wsclean -name selfcal2-band3 -size 1400 1400 -scale 1amin -niter 10000 -mgain 0.8 -weight natural -auto-threshold 1.5 -quiet ${obsnum}112-114.ms
wsclean -name selfcal2-band4 -size 1400 1400 -scale 1amin -niter 10000 -mgain 0.8 -weight natural -auto-threshold 1.5 -quiet ${obsnum}147-153.ms


### interpolate for flagged freq
#cp /home/sprabu/customPython/interpolate .
#myPython ./interpolate --inputFile round2.bin --outputFile ${obsnum}.bin


end=`date +%s`
runtime=$((end-start))
echo "the job run time ${runtime}"


}

