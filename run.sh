#!/bin/bash

# re-enroll-munki.sh
# 2017 Gordon Young  - VGS - gordon.young@vgs.io
# A script to bootstrap macOSX clients with a Munki installation: https://www.munki.org
# Munki is a set of tools that, used together with a webserver-based repository of packages and package metadata,
# can be used by OS X administrators to manage software installs (and in many cases removals) on OS X client machines

# configure a standard hostname
HOSTNME="lpt-$(ioreg -l | awk -F'"' '/IOPlatformSerialNumber/ { print $4;}').corp.verygood.systems"
LOCALHOSTNME="lpt-$(ioreg -l | awk -F'"' '/IOPlatformSerialNumber/ { print $4;}')"
COMPUTERNME="lpt-$(ioreg -l | awk -F'"' '/IOPlatformSerialNumber/ { print $4;}')"

# ^^ looks like this: lpt-C02TP316HF1R.corp.verygood.systems ^^

# Set the hostname
sudo scutil --set HostName $HOSTNME
sudo scutil --set LocalHostName $LOCALHOSTNME
sudo scutil --set ComputerName $COMPUTERNME

# Clear DNS cache
sudo dscacheutil -flushcache

# VGS Munki Server properties
PACKAGING_SERVER_URL="https://wksmgmt-repo.apps.verygood.systems/munki_repo"
MWA_HOST="https://wksmgmt.apps.verygood.systems" # VGS Munki WebAdmin and Reporting Server
SAL_HOST="https://wksmgmt.apps.verygood.systems"
SAL_KEY="kf3arebddxmppn5908wv5vl1yjn0rczy36cnxs3an5jym29tvcztdas3d0cpzizh7btydhzezs1mqrazhag855ywltmfy5cx5pts2a4ew4i5r4qgtwgwko8y7pl2utmc"

# GitHub Munki sources
MUNKI_PKG="munkitools-3.1.1.3447.pkg" # Grab this package
MUNKI_URL="https://github.com/munki/munki/releases/download/v3.1.1/"


# TODO Enable client side TLS:Mutual_Auth client certs...
MWA_SSL_CERTIFICATE="" # TLS Client certificate for TLS Mutual Auth - We'll do this next...
MWA_ALLOWED_NETWORKS=( ) # restrict source networks

# Download and install the munki toolchain
echo "Installing the munki tools..."
pushd /tmp
sudo /usr/bin/curl -OL $MUNKI_URL/$MUNKI_PKG
sudo /usr/sbin/installer -pkg $MUNKI_PKG -target /
popd

# Set some Munki properties
echo "Setting munki properties..."
sudo /usr/bin/defaults write /Library/Preferences/ManagedInstalls SoftwareRepoURL $PACKAGING_SERVER_URL

# Set some SALOpenSource properties
sudo /usr/bin/defaults write /Library/Preferences/com.github.salopensource.sal ServerURL $SAL_HOST
sudo defaults write /Library/Preferences/com.github.salopensource.sal key $SAL_KEY

# Check in the machine to Munki to get initial packages that have been scoped
echo "Checking for packages..."
sudo /usr/local/munki/managedsoftwareupdate -v --checkonly

# Install the packages that have been scoped
echo "Installing packages..."
sudo /usr/local/munki/managedsoftwareupdate -v --installonly
