#!/usr/bin/env bash

# Script to automate the build and deployment of the IATI SSOT reference site.
# Builds base version branches using default directory and host configuration.


./build_iati_standard.sh -c
./deploy_iati_standard.sh