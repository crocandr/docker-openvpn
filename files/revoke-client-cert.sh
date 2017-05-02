#!/bin/bash

# --- VARS ---
OpenVPNConfDir="/etc/openvpn"
EasyRSADir="$OpenVPNConfDir/easy-rsa"
KeysBaseDir="$EasyRSADir/keys"

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
        echo "Usage: $0 <crtfile>"
        echo "Example: $0 $KeysBaseDir/johndon.crt"
        exit 1
fi

# check keyname
if [ ! $( find $KeysBaseDir -iname *$certname*crt | wc -l ) -gt 0 ]
then
        echo "Crt file not exists: $certname"
        echo "Please give another file name!"
        exit 1
fi

# import keyvars
source $EasyRSADir/vars

# revoke
$EasyRSADir/revoke-full "$certname"

# delete config file
[ -e "$KeysBaseDir/$certname-conf.ovpn" ] && rm -f "$KeysBaseDir/$certname-conf.ovpn"
