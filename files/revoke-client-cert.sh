#!/bin/bash

# --- VARS ---
EasyRSADir="/etc/openvpn/easy-rsa"
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
        echo "Please give another file with full path!"
        exit 1
fi

# import keyvars
source $EasyRSADir/vars

# revoke
$EasyRSADir/revoke-full "$certname"
err=$?
if [ $err -eq 1 ]
then
  echo "revoking problem"
  exit 1
fi

# delete config file
if [ -e "$KeysBaseDir/$certname-conf.ovpn" ]
then
  rm -f "$KeysBaseDir/$certname-conf.ovpn"
fi

