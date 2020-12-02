#!/bin/bash

usage()
{
echo "cotter.sh [-o obsnum] [-m cluster] [-a account] [-d dependancy]
	-o obsnum	: the observation id
	-m cluster	: the hpc cluster to run.default=garrawarla
	-d dep		: the dependant jobs id
	-a account	: the pawsey account to use.default mwasci" 1>&2;
exit 1;
}

obsnum=
account="mwasci"
cluster="garrawarla"
dep=
while getopts 'o:m:d:a:' OPTION
do
    case "$OPTION" in
        o)
            obsnum=${OPTARG}
            ;;
	m)
            cluster=${OPTARG}
	    ;;
	d)
	    dep=${OPTARG}
	    ;;
	a)
	    account=${OPTARG}
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


### submit the cotter job
script="${base}queue/cotter_${obsnum}.sh"
cat ${base}/bin/cotter.sh | sed -e "s:OBSNUM:${obsnum}:g" \
                                 -e "s:BASE:${base}:g" > ${script}
output="${base}queue/logs/cotter_${obsnum}.o%A"
error="${base}queue/logs/cotter_${obsnum}.e%A"
sub="sbatch --begin=now+15 --output=${output} --error=${error} ${depend} -A ${account} -M ${cluster} ${script}"
jobid1=($(${sub}))
jobid1=${jobid1[3]}
# rename the err/output files as we now know the jobid
error=`echo ${error} | sed "s/%A/${jobid1}/"`
output=`echo ${output} | sed "s/%A/${jobid1}/"`

echo "Submitted cotter job as ${jobid1}"




