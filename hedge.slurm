#!/bin/bash
#SBATCH -N 1
#SBATCH -n 30
#SBATCH --mem=80G
#SBATCH -t 04:00:00
#SBATCH --mail-user=ndk9pg@virginia.edu
#SBATCH --mail-type=BEGIN
#SBATCH -p standard
#SBATCH -A aecapstonedesign

module load gcc/11.4.0 openmpi/4.1.4 openfoam/v2312 scotch
source $FOAM_BASH

./Allclean.sh
blockMesh
decomposePar
mpirun snappyHexMesh -parallel
reconstructParMesh
