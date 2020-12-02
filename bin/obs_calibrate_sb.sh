#!/bin/bash
usage()
{
echo "calibrate_sb.sh [-o obsnum] [-m model] [-d wget link] [-a account] [-m machine]
	-o obsnum	: observation id
	-d wget link	: the wget link for the obs
	-m model	: the calibrator model
	-a account	: the pawsey account.default=mwasci
	-c machine	: the cluster to run the job.default=garrawarla" 1>&2;
exit 1;
}

obsnum=
model=
account="mwasci"
link=
machine="garrawarla"
while getopts 'o:m:a:c:d:' OPTION
do
    case "$OPTION" in
        o)
            obsnum=${OPTARG}
            ;;
        m)
            model=${OPTARG}
            ;;
        d)
            link=${OPTARG}
            ;;
        a)
            account=${OPTARG}
            ;;
        c)
            machine=${OPTARG}
            ;;
        ? | : | h)
            usage
            ;;
    esac
done




# if obsid is empty then just pring help
if [[ -z ${obsnum} ]]
then
    usage
fi

base=/astro/mwasci/sprabu/satellites/MWA-calibration/

script="${base}queue/calibrate_sb_${obsnum}.sh"
cat ${base}bin/calibrate_sb.sh | sed -e "s:OBSNUM:${obsnum}:g" \
                                -e "s:BASE:${base}:g" > ${script}
output="${base}queue/logs/calibrate_sb_${obsnum}.o%A"
error="${base}queue/logs/calibrate_sb_${obsnum}.e%A"
sub="sbatch --begin=now+15 --output=${output} --error=${error} -M ${machine} -A ${account} ${script} -m ${model} -l ${link}" 
jobid=($(${sub}))
jobid=${jobid[3]}

# rename the err/output files as we now know the jobid
error=`echo ${error} | sed "s/%A/${jobid}/"`
output=`echo ${output} | sed "s/%A/${jobid}/"`

echo "Submitted calibration job as ${jobid}"



