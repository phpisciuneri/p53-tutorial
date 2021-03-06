#!/bin/bash

if [ -n "$SEG_DEBUG" ] ; then
    set -x
    env | sort
fi

cd $WEST_SIM_ROOT

DIST=_p53_dist_$$.xvg
DIST_OUT=_p53_dist_$$.out.xvg
RMSD=_p53_rmsd_$$.xvg
RMSD_OUT=_p53_rmsd_$$.out.xvg

function cleanup() {
    rm -f $DIST $RMSD
}

trap cleanup EXIT

# Get progress coordinate
if [ ${G_DIST} ]; then
    # For GROMACS 4, use trjconv, g_rms, and g_dist.
    # Currently, GROMACS 5 isn't supported.

    # Generate a .tpr file for use in g_dist and g_rms
    rm -f $WEST_STRUCT_DATA_REF.tpr
    $GROMPP -f $MDP_LOC -c $WEST_STRUCT_DATA_REF.gro -p $TOP_LOC \
          -t $WEST_STRUCT_DATA_REF.trr -o $WEST_STRUCT_DATA_REF.tpr -po md_out.mdp -n $NDX_LOC
    rm md_out.mdp

    # Update the command, then calculate the first dimension of the progress coordinate: end to end distance.
    COMMAND="18 \n 19 \n"
    echo -e $COMMAND \
      | $G_DIST -f $WEST_STRUCT_DATA_REF.gro -s $WEST_STRUCT_DATA_REF.tpr -o $DIST -xvg none -n $NDX_LOC || exit 1
    cat $DIST | awk '{print $2*10;}' > $DIST_OUT

    # Update the command again, then run g_rms to calculate to second the dimension: the heavy atom rmsd of the protein aligned on itself.
    COMMAND="2 \n 2 \n"
    echo -e $COMMAND \
      | $G_RMS -s $REF_LOC -f $WEST_STRUCT_DATA_REF.gro -n $NDX_LOC -xvg none -o $RMSD || exit 1
    cat $RMSD | awk '{print $2*10;}' > $WEST_PCOORD_RETURN

    # Return the true pcoord.
    #paste $DIST_OUT $RMSD_OUT > $WEST_PCOORD_RETURN || exit 1
    #cat $RMSD_OUT > $WEST_PCOORD_RETURN || exit 1

    rm -f $DIST $DIST_OUT $RMSD $RMSD_OUT

fi

if [ -n "$SEG_DEBUG" ] ; then
    head -v $WEST_PCOORD_RETURN
fi
