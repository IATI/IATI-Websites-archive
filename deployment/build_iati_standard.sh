#!/usr/bin/env bash

# Script to automate the deployment of the IATI Standard documentation.
# Assumes running on webserver3 and the documentation for versions 1.04,
# 1.05, 2.01 & 2.02 are all to be regenerated.

# Software dependencies must already be installed.

# Script must be run as user 'iati'. This ensures user 'iati' is the owner
# of all files generated:
# $ sudo -u iati ./build_iati_standard.sh

OPTIND=1         # Reset in case getopts has been used previously in the shell.

DEFAULT_DIR=/var/www/dev.reference.iatistandard.org/html

while getopts "d:ch" opt; do
    echo $OPTARG
    case "$opt" in
    d)  DIRECTORY=$OPTARG
        ;;
    c)  CHECKOUT=true
        ;;
    h)  echo "Usage:"
        echo "    build_iati_standard.sh [-d [path/to/dir]] [-h] [-c] [-p]."
        echo "    -d [path/to/dir]    specify a build path for the SSOT"
        echo "    -c                  force check out base branches (version-2.03 etc) for build"
        echo "    -p                  use Python 2.x virtual environment"
        echo "    -h                  display this menu"
        exit 0
        ;;
    \? )
        echo "Option invalid: -$OPTARG" 1>&2
        exit 1
        ;;
    esac
done

shift $((OPTIND-1))

[ "${1:-}" = "--" ] && shift

cd ${DIRECTORY:-$DEFAULT_DIR}


# Ensure documentation and template dependencies are on the 'live' branches and up-to-date
for f in IATI-Developer-Documentation/ IATI-Guidance/ IATI-Websites/; do
    cd $f
    echo -e "NOW IN FOLDER: $PWD \n\n"

    git checkout live
    git pull
    echo -e "DONE CODE PULLS: $PWD \n\n"

    cd ..
done
echo -e "UPDATED DOCS & TEMPLATES \n\n"


# Regenerate all versions of the sites, saving HTML outputs in '_build/dirhtml'
for f in 2.01 2.02 2.03; do
    cd $f
    site_folder="${f//.}"
    echo -e "NOW IN FOLDER: $PWD \n\n"



    # Ensure that directories are up to date and clean of changes
    git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
    git fetch origin

    git reset --hard HEAD^1
    git clean -fd

    # Ensure code and submodules are up-to-date with origin
    if [ "$CHECKOUT" = true ] ; then
        git checkout version-$f
        git pull origin version-$f
    else
        git pull
    fi

    git submodule deinit --all -f
    git submodule update --init --recursive
    echo -e "DONE CODE PULLS: $f \n\n"

    # Set-up the environment and repository dependencies
    # Remove existing pyenv to replace with new
    if [ -d "pyenv/" ]; then
        echo "REMOVING EXISTING PYENV" 
        rm -Rf pyenv/
    fi


    python3 -m venv pyenv
    source pyenv/bin/activate
    pip install -r requirements.txt
    echo -e "DONE VIRTUALENV AND PIP: $f \n\n"

    # Symlink styles
    echo "SYMLINKING STYLING"
    cd IATI-Extra-Documentation/en
    ln -s ../../../IATI-Websites/iatistandard/_templates/ ./
    ln -s ../../../IATI-Websites/iatistandard/_static/ ./

    # Generate a version of the documentation
    cd ../../

    # Run script that creates the static text of the SSOT (using the codelists to generate tables etc.)
    ./combined_gen.sh
    deactivate
    echo -e "DONE GENERATING SITE: $f \n\n"

    cd ..
done
