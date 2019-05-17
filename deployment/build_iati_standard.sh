#!/usr/bin/env bash

# Script to automate the deployment of the IATI Standard documentation.
# Assumes running on webserver3 and the documentation for versions 1.04,
# 1.05, 2.01 & 2.02 are all to be regenerated.

# Maintained under the `iati-bot` gist account.

# Software dependencies must already be installed.

# Script must be run as user 'ssot'. This ensures user 'ssot' is the owner
# of all files generated:
# $ sudo -u ssot ./deploy_iati_standard.sh

# The public key for webserver3 must be added to the 'iatiuser' account on
# webserver5.

OPTIND=1         # Reset in case getopts has been used previously in the shell.

DEFAULT_DIR=/home/ssot/live

while getopts "d:" opt; do
    echo $OPTARG
    case "$opt" in
    d)  DIRECTORY=$OPTARG
        ;;
    esac
done

shift $((OPTIND-1))

[ "${1:-}" = "--" ] && shift

cd ${DIRECTORY:-$DEFAULT_DIR}


# Ensure documentation and template dependencies are on the 'live' branches and up-to-date
for f in IATI-Developer-Documentation/ IATI-Guidance/ IATI-Websites/; do
    cd $f
    echo -e "NOW IN FOLDER: $f \n\n"

    git checkout live
    git pull
    echo -e "DONE CODE PULLS: $f \n\n"

    cd ..
done
echo -e "UPDATED DOCS & TEMPLATES \n\n"


# Regenerate all versions of the sites, saving HTML outputs in '_build/dirhtml'
for f in 2.01 2.02 2.03 1.05 1.04; do
    cd $f
    echo -e "NOW IN FOLDER: $f \n\n"

    # Ensure code and submodules are up-to-date with origin
    git pull
    git submodule update
    echo -e "DONE CODE PULLS: $f \n\n"

    # Set-up the environment and repository dependencies
    source pyenv/bin/activate
    pip install -r requirements.txt
    echo -e "DONE VIRTUALENV AND PIP: $f \n\n"

    # Run script that creates the static text of the SSOT (using the codelists to generate tables etc.)
    ./combined_gen.sh
    deactivate
    echo -e "DONE GENERATING SITE: $f \n\n"

    site_folder="${f//.}"

    cd ..
done