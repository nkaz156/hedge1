#!/bin/bash
cd "$(dirname "$0")"

# ---------------------------------------------------------------------------- #
#                               Define Functions                               #
# ---------------------------------------------------------------------------- #

usage() { # Script information printout
    echo "Usage: ${0} [-msl] [-p PROCESSORS]" >&2
    echo "Automatically runs whatever OpenFOAM case it is in"
    echo "  -p PROCESSORS       Specify number of processor cores to use"
    echo "  -m                  Runs mesher specified in script"
    echo "  -s                  Runs CFD solver specified in ./system/controlDict"
    echo "  -l                  Writes mesher/solver output to log files"
    echo "  -w                  Wait for confirmation to run each component"
    echo "  -v                  Verbose mode (print program status updates)"
    exit 1
}

print() {
    if [[ "${VERBOSE}" = 'true' ]]
    then
        local MSG="${@}"
        echo "${MSG}"
    fi
}

cleanCase() {
    # echo "Press Enter to clean the old mesh"
    # read
    echo "Deleting old files"
    rm -r processor*
    rm -r constant/polyMesh
    for dir in */; do
        # Remove the trailing slash from the directory name
        dir=${dir%/}

        # Check if the name is a number and is not "0"
        if [[ "$dir" =~ ^[0-9]+$ ]] && [[ "$dir" -ne 0 ]]; then
            echo "Removing directory: $dir"
            rm -r "$dir"
        fi
    done
}

waitfor() {
    local MSG="${@}" # any function input
    if [[ "${WAIT}" = 'true' ]]
    then
        echo "${MSG} - Press Enter to continue"
        read  # wait for user input
    else 
        echo "${MSG}"
    fi
}

replace_line_in_file() {
    if [ "$#" -ne 3 ]; then
        echo "Usage: $0 <file> <search_string> <replacement_text>"
        exit 1
    fi

    local file=$1
    local search_string=$2
    local replacement_text=$3

    # Check if file exists
    if [ ! -f "$file" ]; then
        echo "Error: File '$file' not found."
        exit 1
    fi

    # Check if the search string exists in the file
    if ! grep -q "$search_string" "$file"; then
        echo "Error: Search string '$search_string' not found in '$file'."
        exit 1
    fi

    # Use sed to find and replace the entire line
    sed -i "/$search_string/c\\$replacement_text" "$file"

    echo "$file updated successfully"
    return 0
}


# ---------------------------------------------------------------------------- #
#                              Get input arguments                             #
# ---------------------------------------------------------------------------- #

while getopts p:mslwv OPTION # colon (:) requires an input with -p
do
    case ${OPTION} in
    p)
        numProc="${OPTARG}"
        PAR='true'
        print "Running with ${numProc} processor cores"
        ;;
    m)
        RUNMESH='true'
        print "Running with mesher enabled"
        ;;
    s)  
        SOLVER='true'
        print "Running with solver enabled"
        ;;
    l)
        LOGTOFILE='true'
        print "Logging to external file"
        ;;
    w)
        WAIT='true'
        print "Wait mode enabled"
        ;;
    v)
        VERBOSE='true'
        ;;
    ?)
        echo "Invalid input argument" >&2
        usage
        exit 1
        ;;
    esac
done

# ---------------------------------------------------------------------------- #
# ---------------------------------------------------------------------------- #
#                                   CODE BODY                                  #
# ---------------------------------------------------------------------------- #
# ---------------------------------------------------------------------------- #
waitfor "Cleaning case files"
cleanCase

if [[ "${RUNMESH}" = 'true' ]]
    then
    waitfor "Background Meshing"
    blockMesh
fi



if [[ "${PAR}" = 'true' && "${RUNMESH}" = 'true' ]] 
then
    waitfor "Running snappyHexMesh"
    replace_line_in_file "./system/decomposeParDict" "numberOfSubdomains" "numberOfSubdomains  $numProc;"
    print "conducting parallel decompostition"
    decomposePar
    print "Running in parallel"
    mpirun -np $numProc snappyHexMesh -parallel
    print "Reconstructing parallel mesh"
    reconstructParMesh
elif [[ "${RUNMESH}" = 'true' ]]
    then
    waitfor "Running snappyHexMesh"
    print "Running in serial"
    snappyHexMesh
fi

echo "Done!"
