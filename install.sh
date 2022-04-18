#!/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "ERROR: This script must be run as root" 1>&2
   exit 1
fi

echo "Downloading latest vaf binary from releases"
wget https://github.com/d4rckh/vaf/releases/latest/download/Linux-vaf
echo "Deleting previous installation of var (if it exists)"
rm /usr/bin/vaf
echo "Moving vaf to /usr/bin/vaf"
mv Linux-vaf /usr/bin/vaf
echo
echo "vaf installed successfully, you can now run 'vaf'"
