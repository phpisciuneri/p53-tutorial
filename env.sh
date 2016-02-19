# This file defines where WEST and GROMACS can be found
# Modify to taste
case $HOSTNAME in
    login[0][a,b].frank.sam.pitt.edu | n*)
        # Suitable for Frank and the nodes on Frank.
        # However, any hostname can be added to this environment file to switch this tutorial
        # to other clusters.
        # Merely add another case statement; google bash case examples.

        # Load the modules!
        echo "LOADING MODULES FOR FRANK."

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
        export WEST_ROOT=$WEST_ROOT
        echo "simulation $SIM_NAME root is $WEST_SIM_ROOT"
esac


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
