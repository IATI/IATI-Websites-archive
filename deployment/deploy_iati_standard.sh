#!/usr/bin/env bash

# Script to automate the deployment of the IATI Standard documentation.
# Assumes running on webserver3 and the documentation for versions 1.04,
# 1.05, 2.01 & 2.02 are all to be regenerated.

# Maintained under the `iati-bot` gist account.

# Software dependencies must already be installed.

# Script must be run as user 'ssot'. This ensures user 'ssot' is the owner
# of all files generated:
# $ sudo -u ssot ./deploy_iati_standard.sh

# The public key for webserver3 must be added to the 'iatiuser' account on
# webserver5.

cd /home/ssot/live


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

    # Copy the output files to the live webserver
    scp -r docs-copy/en/_build/dirhtml iatiuser@reference.iatistandard.org:~/ssot/${site_folder}-new
    # Real live rolder is '/home/iatiuser/ssot/'

    # Make a backup version of the current site, and make the new version live
    ssh iatiuser@reference.iatistandard.org "cd ~/ssot/;mv ${site_folder} ${site_folder}-backup-$(date +\%Y\%m\%d-\%s);mv ${site_folder}-new ${site_folder}"

    cd ..
done
