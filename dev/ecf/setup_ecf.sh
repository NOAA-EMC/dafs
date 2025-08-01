#!/bin/bash

# The script sets up the ecflow suite definition file for the DAFS workflow
# Usage: ./setup_ecf.sh [-d PDYcyc] [-x EXPID] [-v MODELVER]
#   PDYcyc: Test date in YYYYMMDDHH format.  If blank, the current date and NRT mode is used (default: blank)
#   EXPID: Experiment ID to distinguish different test runs (default: None)
#   MODELVER: Model version 
# Example: 1. ./setup_ecf.sh -d 2020011012 -x x001 -v v1.0.0  # Use the specified date and experiment ID and model version
#          2. ./setup_ecf.sh -x x001  # Use the current date and NRT mode and the package path ended with dafs.vX.Y.Z
#
# Setting up ecflow suite requires the package to be cloned in a directory matching 'dafs.vX.Y.Z'
# where X, Y, Z are numbers
# The script replaces @VARIABLE@ names in suite definition files with values
# and links ecflow scripts in the ecf/ directory
#
# The script is expected to be run after the package is cloned and executables are built

set -eu
set -x
# Function to print usage
_usage() {
    echo "Usage: ./setup_ecf.sh [-d PDYcyc] [-x EXPID] [-v MODELVER]"
    echo "  PDYcyc: Test date in YYYYMMDDHH format. If blank, the current date and NRT mode is used (default: blank)"
    echo "  EXPID: Experiment ID to distinguish different test runs (default: None)"
    echo "  MODELVER: Model version
    echo "Example: 1. ./setup_ecf.sh -d 2020011012 -x x001 -v v1.0.0  # Use the specified date and experiment ID and model version"
    echo "         2. ./setup_ecf.sh -x x001  # Use the current date and NRT mode and the package path ended with dafs.vX.Y.Z "
}

# Set defaults for key-value arguments
PDYcyc=""
EXPID=""
MODELVER=""

# Parse key-value arguments using getopts
while getopts ":d:x:v:h" opt; do
    case ${opt} in
    d)
        PDYcyc=${OPTARG}
        ;;
    x)
        EXPID=${OPTARG}
        ;;
    v)
        MODELVER=${OPTARG}
        ;;
    h)
        _usage
        exit 0
        ;;
    \?)
        echo "Invalid option: -${OPTARG}" >&2
        _usage
        exit 1
        ;;
    :)
        echo "Option -${OPTARG} requires an argument." >&2
        _usage
        exit 1
        ;;
    esac
done
shift $((OPTIND - 1))

# Get the root of the cloned DAFS directory
declare -r DIR_ROOT=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}")")/../.." && pwd -P)

model="dafs"
if [[ -n "${MODELVER}" ]] ; then
    modelver="${MODELVER}"
    packagename="dafs.${modelver}"
else
    modelver=$(echo ${DIR_ROOT} | perl -pe "s:.*?/${model}\.(v[\d\.a-z]+).*:\1:")
    packagename=$(basename ${DIR_ROOT})
fi
packagehome="${DIR_ROOT}"

# Check if the directory ends with "dafs.vX.Y.Z"
pattern="^dafs\.v([0-9\.a-z]+).$"
if [[ ! "${packagename}" =~ ${pattern} ]]; then
    echo "FATAL ERROR: The package '${packagename}' should be cloned in a directory matching 'dafs.vX.Y.Z'"
    echo "             X, Y, Z are numbers"
    exit 1
fi

# Check if PDYcyc is provided and in the right format to set template used to either dafs.def.tmpl or dafs_nrt.def.tmpl
if [[ -n "${PDYcyc}" ]]; then
    template="dafs.def.tmpl"
else
    template="dafs_nrt.def.tmpl"
fi

# Echo out the settings for the user
echo "Settings:"
echo "  Model: ${model}.${modelver}"
echo "  Package Home: ${packagehome}"
if [[ -n "${EXPID}" ]]; then
    echo "  Experiment ID: ${EXPID}"
fi
echo "  Test date: ${PDYcyc}"
echo "  ecflow suite def template: ${template}"

# Replace @VARIABLE@ names in suite definition files with values
echo "Create ecflow suite definition file 'dafs${EXPID}.def' in ... ecf/def"
sed -e "s|@EXPID@|${EXPID}|g" \
    -e "s|@MACHINE_SITE@|${MACHINE_SITE:-development}|g" \
    -e "s|@USER@|${USER}|g" \
    -e "s|@MODELVER@|${modelver}|g" \
    -e "s|@PACKAGEHOME@|${packagehome}|g" \
    -e "s|@PDY@|${PDYcyc:0:8}|g" \
    -e "s|@CYC@|${PDYcyc:8:2}|g" \
    "${DIR_ROOT}/ecf/def/${template}" >"${DIR_ROOT}/ecf/def/dafs${EXPID}.def"
if [[ -n "${PDYcyc}" ]]; then
    CYC=${PDYcyc:8:2}
    if [[ $(( 10#${CYC} / 3 * 3 )) -ne $(( 10#${CYC} )) ]] ; then
	sed -e "/family alaska/,/endfamily alaska/d" -i "${DIR_ROOT}/ecf/def/dafs${EXPID}.def"
    fi
fi

# Link ecflow scripts
echo "Link ecflow scripts in ... ecf/"
cd "${DIR_ROOT}/ecf" || exit 1
./setup_ecf_links.sh

echo "... done"
