#!/bin/bash

# --- VARS ---
EasyRSADir="/etc/openvpn/easy-rsa"
KeysBaseDir="$EasyRSADir/keys"

ClientConfTemplate="$EasyRSADir/templates/client.conf"
ServerCAFile="/etc/openvpn/ca.crt"

# if ServerAddress is not defined as sys Environment variable
if [ -z $ServerAddress ]
then
  # find public IP address
  PUBIP=$( curl -L -k http://ifconfig.co || exit 1 )
  # failsafe PUBIP
  [ $PUBIP ] || PUBIP=$( curl -L -k http://icanhazip.com || exit 1 )
  [ $PUBIP ] || PUBIP=$( curl -L -k http://ident.me || exit 1 )
  [ $PUBIP ] || PUBIP=$( curl -L -k http://eth0.me || exit 1 )
  if [ ! -z "$PUBIP" ]
  then
    ServerAddress="$PUBIP"
  fi
fi

# if ServerPort is not defined as sys Environment variable
[ -z $ServerPort ] && { ServerPort="1194"; }

# --- SCRIPT ---

if [ "$1" ]
then
        keyname="$1"
else
        echo "Usage: $0 <keyname>"
        echo "Example: $0 DonJohn"
        exit 1
fi

# check keyname
if [ -e "$KeysBaseDir/$keyname.crt" ]
then
        echo "key file already exists: $keyname.crt"
        echo "Please give another name!"
        echo "Example: $keyname-`date +%Y`"
        exit 1
fi

# import keyvars
source $EasyRSADir/vars

# genkey
$EasyRSADir/pkitool "$keyname"

# genconf
ClientConf=$KeysBaseDir/$keyname-conf.ovpn
cp -f $ClientConfTemplate $ClientConf

#  serveraddress
sed -i 's@--ServerAddress--@'"$ServerAddress"'@g' $ClientConf
# serverport
sed -i 's@--ServerPort--@'"$ServerPort"'@g' $ClientConf

#  insert ca
sed -i '/<ca>/r '"$ServerCAFile"'' $ClientConf
#  insert cert
ls -hal $KeysBaseDir/$keyname.crt
sed -i '/<cert>/r '"$KeysBaseDir/$keyname.crt"'' $ClientConf
#  insert key
sed -i '/<key>/r '"$KeysBaseDir/$keyname.key"'' $ClientConf

GenDate=$( date +"%Y%m%d %T" )
echo -e "\n\n# Generated: $GenDate" >> $KeysBaseDir/$keyname-conf.ovpn


# MSG
echo ""
echo ""
echo "Client config file: $KeysBaseDir/$keyname-conf.ovpn"

