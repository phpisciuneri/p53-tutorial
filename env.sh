#!/bin/bash
#
# Set up environment for WESTPA run
#
module purge
module load queue
module load westpa/anaconda2-2.4.1

# Should we use the local scratch?
export USE_LOCAL_SCRATCH=1
export SCRATCHROOT=$SCRATCH
export SWROOT=""

# Explicitly name our simulation root directory
if [[ -z "$WEST_SIM_ROOT" ]]; then
    export WEST_SIM_ROOT="$PWD"
fi
export SIM_NAME=$(basename $WEST_SIM_ROOT)

# Setting variables for use in runseg.sh and get_pcoord.sh.
export WEST_ZMQ_DIRECTORY=server_files
export WEST_LOG_DIRECTORY=job_logs
export MDRUN=$(which mdrun)
export GROMPP=$(which grompp)
export G_DIST=$(which g_dist)
export G_RMS=$(which g_rms)
export TRJCONV=$(which trjconv)
export GMINDIST=$(which g_mindist)
export GRAMA=$(which g_rama)
export TOP_LOC=$WEST_SIM_ROOT/gromacs_config/p53.top
export ITP_LOC=$WEST_SIM_ROOT/gromacs_config/conf.itp
export ION_LOC=$WEST_SIM_ROOT/gromacs_config/ions.itp
export NDX_LOC=$WEST_SIM_ROOT/gromacs_config/p53.ndx
export REF_LOC=$WEST_SIM_ROOT/gromacs_config/coil.gro
export MDP_LOC=$WEST_SIM_ROOT/gromacs_config/md.mdp
export GMX_CFG=$WEST_SIM_ROOT/gromacs_config/
export TOP=p53.top
export NDX=p53.ndx
export REF=coil.gro
export MDP=md.mdp