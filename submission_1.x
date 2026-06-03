#!/bin/bash

# Define the path to the executable
qlmp="/qlammps.sh"

# Check if the file exists and is executable
if [[ -x "$qlmp" ]]; then
    # Execute the file
    "$qlmp"
else
    echo "Error: $executable_path not found or not executable."
    exit 1
fi

#$qlmp -c 128 -n 1 -w 96:00:00 -q standard -f Polymer_Densify_R1.in
$qlmp -c 128 -n 1 -w 168:00:00 -q standard -f Polymer_AN_R1.in
$qlmp -c 128 -n 1 -w 96:00:00 -q standard -f Polymer_ANEq_R1.in
$qlmp -c 128 -n 1 -w 96:00:00 -q standard -f Polymer_ANEqPly_R1_1.in
$qlmp -c 128 -n 1 -w 96:00:00 -q standard -f Polymer_ANEqPly_R1_2.in
$qlmp -c 128 -n 1 -w 168:00:00 -q standard -f Polymer_ANEqPlyAN_R1.in
$qlmp -c 128 -n 1 -w 96:00:00 -q standard -f Polymer_ANEqPlyANEq_R1.in

#FIRST=$(qsub Polymer_Densify_R1.in.sh)

FIRST=$(qsub Polymer_AN_R1.in.sh)

SECOND=$(qsub -W depend=afterok:$FIRST Polymer_ANEq_R1.in.sh)

THIRD=$(qsub -W depend=afterok:$SECOND Polymer_ANEqPly_R1_1.in.sh)

FOURTH=$(qsub -W depend=afterok:$THIRD Polymer_ANEqPly_R1_2.in.sh)

FIFTH=$(qsub -W depend=afterok:$FOURTH Polymer_ANEqPlyAN_R1.in.sh)

SIXTH=$(qsub -W depend=afterok:$FIFTH Polymer_ANEqPlyANEq_R1.in.sh)
