#!/bin/bash

# --- VARS ---
EasyRSADir="/etc/openvpn/easy-rsa"
ProfileDir="$EasyRSADir/profile"

# --- SCRIPT ---

if [ "$1" ]
then
        if [ -e "$1" ]
        then
                certname=$( basename $1 | sed s@.crt@@g )
        else
                certname=$1
        fi
else
        echo "Usage: $0 <crt name>"
        echo -e "Example:  $0 johndon"
        exit 1
fi

# import keyvars
source $EasyRSADir/vars

# revoke
cd $EasyRSADir
echo -e "yes\n" | $EasyRSADir/easyrsa revoke "$certname"

# delete config file
[ -e "$ProfileDir/$certname-conf.ovpn" ] && rm -f "$ProfileDir/$certname-conf.ovpn"

# update crl
cd $EasyRSADir
$EasyRSADir/easyrsa gen-crl
