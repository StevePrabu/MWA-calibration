#!/bin/bash
usage()
{
echo "infield_sb.sh [-o obsnum] [-a account] [-m machine] [-d dep]
	-o obsnum	: observation id
	-d dep		: dependant job
	-a account	: the pawsey account.default=mwasci
	-c machine	: the cluster to run the job.default=garrawarla" 1>&2;
exit 1;
}

obsnum=
model=
account="mwasci"
dep=
machine="garrawarla"
while getopts 'o:a:c:d:' OPTION
do
    case "$OPTION" in
        o)
            obsnum=${OPTARG}
            ;;
        d)
            dep=${OPTARG}
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

if [[ ! -z ${dep} ]]
then
    depend="--dependency=afterok:${dep}"
fi



base=/astro/mwasci/sprabu/satellites/MWA-calibration/

script="${base}queue/infield_sb_${obsnum}.sh"
cat ${base}bin/infield_sb.sh | sed -e "s:OBSNUM:${obsnum}:g" \
                                -e "s:BASE:${base}:g" > ${script}
output="${base}queue/logs/infield_sb_${obsnum}.o%A"
error="${base}queue/logs/infield_sb_${obsnum}.e%A"
sub="sbatch --begin=now+15 --output=${output} --error=${error} ${depend} -M ${machine} -A ${account} ${script} -m ${model} -l ${link}" 
jobid=($(${sub}))
jobid=${jobid[3]}

# rename the err/output files as we now know the jobid
error=`echo ${error} | sed "s/%A/${jobid}/"`
output=`echo ${output} | sed "s/%A/${jobid}/"`

echo "Submitted infield calibration job as ${jobid}"



