#!/usr/bin/env bash

# Script to automate the deployment of the IATI Standard documentation.
# Assumes running on webserver3 and the documentation for versions 1.04,
# 1.05, 2.01 & 2.02 are all to be regenerated.

# Software dependencies must already be installed.

# Script must be run as user 'iati'. This ensures user 'iati' is the owner
# of all files generated:
# $ sudo -u iati ./deploy_iati_standard.sh

# The public key for the user that this script is to be run on must
# be an authorised key of the user of the live instance.

DEFAULT_DIR=/var/www/dev.reference.iatistandard.org/html
DEFAULT_SSH_USER=iati
DEFAULT_SSH_HOST=134.209.18.180
DEFAULT_BUILD_DIR=docs-copy/en/_build/dirhtml
DEFAULT_REMOTE_DIR=/var/www/reference.iatistandard.org/html
DEFAULT_BACKUP_DIR=/var/www/reference.iatistandard.org/html/backups

while getopts "d:s:i:b:r:ht:" opt; do
    echo $OPTARG
    case "$opt" in
    d)  DIRECTORY_INPUT=$OPTARG
        ;;
    s)  SSH_USER_INPUT=$OPTARG
        ;;
    i)  SSH_HOST_INPUT=$OPTARG
        ;;
    b)  BUILD_DIR_INPUT=$OPTARG
        ;;
    r)  REMOTE_DIR_INPUT=$OPTARG
        ;;
    t)  BACKUP_DIR_INPUT=$OPTARG
        ;;
    h)  echo "Usage:"
        echo "    deploy_iati_standard.sh [-d [path/to/dir]] [-s [ssh_user] [-i [ssh.host] -b [path/to/dir] [-r [path/to/dir]]]]."
        echo "    -d [path/to/dir]    specify a path for the SSOT"
        echo "    -s                  specify a ssh user for the remote host"
        echo "    -i                  specify a hostname or IP for the remote host"
        echo "    -b [path/to/dir]    specify a local build directory for the HTML output"
        echo "    -r [path/to/dir]    specify a remote path for the SSOT"
        echo "    -t [path/to/dir]    specify a directory for backups"
        exit 0
        ;;
    \? )
        echo "Option invalid: -$OPTARG" 1>&2
        exit 1
        ;;
    esac
done

DIRECTORY=${DIRECTORY_INPUT:-$DEFAULT_DIR}
SSH_USER=${SSH_USER_INPUT:-$DEFAULT_SSH_USER}
SSH_HOST=${SSH_HOST_INPUT:-$DEFAULT_SSH_HOST}
BUILD_DIR=${BUILD_DIR_INPUT:-$DEFAULT_BUILD_DIR}
REMOTE_DIR=${REMOTE_DIR_INPUT:-$DEFAULT_REMOTE_DIR}
BACKUP_DIR=${BACKUP_DIR_INPUT:-$DEFAULT_BACKUP_DIR}


cd $DIRECTORY


# Regenerate all versions of the sites, saving HTML outputs in '_build/dirhtml'
for f in 2.01 2.02 2.03; do
    cd $f
    echo -e "NOW IN FOLDER: $PWD \n\n"

    # Copy the output files to the live webserver
    echo "COPYING BUILD DIRECTORY TO REMOTE AS NEW VERSION"

    scp -r ${BUILD_DIR} ${SSH_USER}@${SSH_HOST}:${REMOTE_DIR}/${f}-new

    # Make a backup version of the current site, and make the new version live
    ssh ${SSH_USER}@${SSH_HOST} "cd ${REMOTE_DIR};if [ -d ${BACKUP_DIR}/${f}.bak ]; then rm -rf ${BACKUP_DIR}/${f}.bak; fi;mv $f ${BACKUP_DIR}/${f}.bak;mv ${f}-new $f;"

    cd ..
done
