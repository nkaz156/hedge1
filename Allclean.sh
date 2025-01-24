#!/bin/sh
cd "${0%/*}" || exit                                # Run from this directory
. ${WM_PROJECT_DIR:?}/bin/tools/CleanFunctions      # Tutorial clean functions
#------------------------------------------------------------------------------

# Copied most cleanCase functions except the one that deletes .foam files from 
# $WM_PROJECT_DIR/bin/tools/CleanFunctions
    cleanTimeDirectories
    cleanAdiosOutput
    cleanDynamicCode
    cleanOptimisation
    cleanPostProcessing

    cleanFaMesh
    cleanPolyMesh
    cleanSnappyFiles

    rm -rf processor*
    rm -rf TDAC
    rm -rf probes*
    rm -rf forces*
    rm -rf graphs*
    rm -rf sets
    rm -rf system/machines

#------------------------------------------------------------------------------
