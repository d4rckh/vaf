#!/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "ERROR: This script must be run as root" 1>&2
   exit 1
fi

echo "Installing dependencies: nim"
apt install nim
echo "Building vaf using 'nimble build'"
nimble build --verbose
echo "Deleting previous installation of var (if it exists)"
rm /usr/bin/vaf
echo "Linking vaf to /usr/bin/vaf"
ln -s `pwd`/vaf /usr/bin/vaf
echo
echo "vaf installed successfully, you can now run 'vaf'"
