#!/bin/bash

date
tic=$(date +%s.%N)
printf "\n"

# Need to set the environment variables relevant for ACORN
source /home/ggalibert/DEFAULT_PATH.env
source /home/ggalibert/STORAGE.env
source /home/ggalibert/ACORN.env

# Run Matlab script to produce FV00 hourly averaged gridded files
matlab -nodisplay -r "cd(getenv('ACORN_EXP')); addpath(fullfile('.', 'Util')); acorn_summary('WERA', false); acorn_summary('CODAR', false); exit"

printf "\n"
date
toc=$(date +%s.%N)
printf "%6.1Fs\tFV00 radial files processed to hourly averaged gridded files\n"  $(echo "$toc - $tic"|bc )

tic=$(date +%s.%N)
printf "\n"

# Move produced files to OPENDAP
rsync -vaR --remove-source-files $DATA/ACORN/WERA/radial_nonQC/output/datafabric/gridded_1havg_currentmap_nonQC/./ $OPENDAP/ACORN/gridded_1h-avg-current-map_non-QC/
rsync -vaR --remove-source-files $DATA/ACORN/CODAR/nonQC_gridded/output/datafabric/gridded_1havg_currentmap_nonQC/./ $OPENDAP/ACORN/gridded_1h-avg-current-map_non-QC/

printf "\n"
date
toc=$(date +%s.%N)
printf "%6.1Fs\tFV00 hourly averaged gridded files moved from WIP to OPENDAP\n"  $(echo "$toc - $tic"|bc )

tic=$(date +%s.%N)
printf "\n"

# Create Rottnest swim plots out of latest hourly gridded files
GMT_OUTPUT=`$ACORN_EXP/GMT/rotswim-hourmap.sh`

printf "\n"
date
toc=$(date +%s.%N)
printf "%6.1Fs\t$GMT_OUTPUT\n"  $(echo "$toc - $tic"|bc )
