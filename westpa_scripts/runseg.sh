#!/bin/bash

if [ -n "$SEG_DEBUG" ] ; then
    set -x
    env | sort
fi

cd $WEST_SIM_ROOT

# Set up the run
mkdir -pv $WEST_CURRENT_SEG_DATA_REF
cd $WEST_CURRENT_SEG_DATA_REF

if [[ "$USE_LOCAL_SCRATCH" == "1" ]] ; then
    # make scratch directory
    WORKDIR=$SCRATCHROOT/$WEST_CURRENT_SEG_DATA_REF
    $SWROOT/bin/mkdir -pv $WORKDIR || exit 1
    cd $WORKDIR || exit 1
    STAGEIN="$SWROOT/bin/cp -avL"
else
    STAGEIN="$SWROOT/bin/ln -sv"
fi


function cleanup() {
    # Clean up.  Copy back what we want, and remove the rest.
    # Also, remove our copied in parent references.  We don't need to keep that.
    $SWROOT/bin/rm -f none.xtc whole.xtc $REF parent.*
    if [[ "$USE_LOCAL_SCRATCH" == "1" ]] ; then
        $SWROOT/bin/cp *.{cpt,xtc,trr,edr,tpr,gro,log,xvg} $WEST_CURRENT_SEG_DATA_REF || exit 1
        cd $WEST_CURRENT_SEG_DATA_REF
        $SWROOT/bin/rm -Rf $WORKDIR
    else
        # Here, we're not using local scratch.  Remove some specific things, in that case.
        $SWROOT/bin/rm -f *.itp *.mdp *.ndx *.top
    fi
}

# Regardless of the reason we exit, run the function cleanup.
trap cleanup EXIT

case $WEST_CURRENT_SEG_INITPOINT_TYPE in
    SEG_INITPOINT_CONTINUES)
        # A continuation from a prior segment
        # $WEST_PARENT_DATA_REF contains the reference to the
        # We'll use the checkpoint files, rather than energy files,
        # in this case.
        #   parent segment
        $STAGEIN $WEST_PARENT_DATA_REF/seg.gro ./parent.gro
        $STAGEIN $WEST_PARENT_DATA_REF/seg.cpt ./parent.cpt
        $STAGEIN $WEST_PARENT_DATA_REF/imaged_ref.gro ./parent_imaged.gro
        $STAGEIN $GMX_CFG/* . || exit 1
        $GROMPP -f $MDP -c parent.gro -t parent.cpt -p $TOP \
          -o seg.tpr -po md_out.mdp
    ;;

    SEG_INITPOINT_NEWTRAJ)
        # Initiation of a new trajectory
        # In truth, there's very little difference between a new trajectory
        # and an old one, except we handle our istates a little differently
        # than a previous segment, and use the .edr file.  
        # For an explicit solvent simulation,
        # all trajectories are considered continuations.
        # We are also copying in the basis state as the imaged ref.
        # $WEST_PARENT_DATA_REF contains the reference to the
        #   appropriate basis or initial state
        $STAGEIN $WEST_PARENT_DATA_REF.edr ./parent.edr
        $STAGEIN $WEST_PARENT_DATA_REF.gro ./parent.gro
        $STAGEIN $WEST_PARENT_DATA_REF.trr ./parent.trr
        $STAGEIN $WEST_PARENT_DATA_REF.gro ./parent_imaged.gro
        $STAGEIN $GMX_CFG/* .
        $GROMPP -f $MDP -c parent.gro -e parent.edr -p $TOP \
          -t parent.trr -o seg.tpr -po md_out.mdp
    ;;

    *)
        # This should never fire.
        echo "unknown init point type $WEST_CURRENT_SEG_INITPOINT_TYPE"
        exit 2
    ;;
esac

# Propagate segment
# It's easiest to set our OpenMP thread count manually here.
export OMP_NUM_THREADS=1
$MDRUN -s   seg.tpr -o seg.trr -c  seg.gro -e seg.edr \
       -cpo seg.cpt -g seg.log -x  seg.xtc -nt 1

# Calculate progress coordinate
# First, we must ensure the protein is correctly imaged.  Essentially, this requires
# referencing a continous trajectory; by passing down an imaged trajectory frame
# from parent to child, we ensure imaging is always correct.
# This is only a problem for g_rms.
# See https://chong.chem.pitt.edu/wewiki/Molecular-scale_systems for more info.
if [ ${G_DIST} ]; then
    # For GROMACS 4, use trjconv, g_rms, and g_dist.
    # Currently, GROMACS 5 isn't supported.

    # Image the system correctly.
    COMMAND="0 \n"
    echo -e $COMMAND \
      | $TRJCONV    -f seg.xtc     -s parent_imaged.gro  -n $NDX -o none.xtc        -pbc none || exit 1
    echo -e $COMMAND \
      | $TRJCONV    -f none.xtc    -s parent_imaged.gro  -n $NDX -o whole.xtc       -pbc whole || exit 1
    echo -e $COMMAND \
      | $TRJCONV    -f whole.xtc   -s parent_imaged.gro  -n $NDX -o nojump.xtc      -pbc nojump || exit 1
    echo -e $COMMAND \
      | $TRJCONV    -f nojump.xtc  -s seg.tpr            -n $NDX -o imaged_ref.gro  -b -1 || exit 1

    # Update the command, then calculate the auxiliary coordinate.
    COMMAND="18 \n 19 \n"
    echo -e $COMMAND \
      | $G_DIST -f seg.xtc -s seg.tpr -o dist.xvg -xvg none -n $NDX || exit 1
    cat dist.xvg | awk '{print $2*10;}' > $WEST_END_TO_END_DIST_RETURN

    # Update the command again, then run g_rms to calculate to progress coordinate: the heavy atom rmsd of the protein aligned on itself.
    COMMAND="2 \n 2 \n"
    echo -e $COMMAND \
      | $G_RMS -s $REF -f nojump.xtc -n $NDX -xvg none || exit 1
    cat rmsd.xvg | awk '{print $2*10;}' > $WEST_PCOORD_RETURN

fi

# Output coordinates.  While we can return coordinates, this is expensive (data size) for a system of this size
# and so by default, it is off for this system.  However, by modifying the variable COMMAND, the group
# which has its coordinates returned can be modified and reduce the cost, so it is sensible to leave it in.

if [ ${WEST_COORD_RETURN} ]; then
    COMMAND="0 \n"
    if [ ${TRJCONV} ]; then
        # For GROMACS 4, use trjconv
        echo -e $COMMAND | $TRJCONV -f seg.trr -s seg.tpr -o seg.pdb
    fi
    cat seg.pdb | grep 'ATOM' \
      | awk '{print $6, $7, $8}' > $WEST_COORD_RETURN
fi

# Output log
if [ ${WEST_LOG_RETURN} ]; then
    cat seg.log \
      | awk '/Started mdrun/ {p=1}; p; /A V E R A G E S/ {p=0}' \
      > $WEST_LOG_RETURN
fi
