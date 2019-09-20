#!/bin/bash

# --- VARS ---
EasyRSADir="/etc/openvpn/easy-rsa"
KeysBaseDir="$EasyRSADir/keys"

ClientConfTemplate="$EasyRSADir/templates/client.conf"
ServerCAFile="/etc/openvpn/ca.crt"
ServerAuthFile="/etc/openvpn/ta.key"

if [ -z "$SERVER_ADDRESS" ]
then
  if [ -f /tmp/server_address.txt ]
  then
    source /tmp/server_address.txt
  fi
fi
[ -z "$SERVER_ADDRESS" ] && { echo "No server address defined."; exit 1; }
[ -z "$SERVER_PORT" ] && { echo "No server port defined."; exit 1; }

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
if [ -e "$KeysBaseDir/pki/issued/$keyname.crt" ]
then
        echo "key file already exists: $keyname.crt"
        echo "Please give another name!"
        echo "Example: $keyname-`date +%Y`"
        exit 1
fi

# import keyvars
source $EasyRSADir/vars

# genkey
#$EasyRSADir/pkitool "$keyname"
cd $EasyRSADir
$EasyRSADir/easyrsa build-client-full "$keyname"

# genconf
ClientConf=$KeysBaseDir/$keyname-conf.ovpn
cp -f $ClientConfTemplate $ClientConf

#  serveraddress
sed -i 's@--ServerAddress--@'"$SERVER_ADDRESS"'@g' $ClientConf
# serverport
sed -i 's@--ServerPort--@'"$SERVER_PORT"'@g' $ClientConf

# server protocol update
sed -i -e "s@^[pP]roto.*@proto $PROTO@g" $ClientConf 

#  insert ca
sed -i '/<ca>/r '"$ServerCAFile"'' $ClientConf
#  insert tls-auth
sed -i '/<tls-auth>/r '"$ServerAuthFile"'' $ClientConf
#  insert cert
ls -hal $KeysBaseDir/pki/issued/$keyname.crt
sed -i '/<cert>/r '"$KeysBaseDir/pki/issued/$keyname.crt"'' $ClientConf
#  insert key
sed -i '/<key>/r '"$KeysBaseDir/pki/private/$keyname.key"'' $ClientConf

GenDate=$( date +"%Y%m%d %T" )
echo -e "\n\n# Generated: $GenDate" >> $KeysBaseDir/$keyname-conf.ovpn


# MSG
echo ""
echo ""
echo "Client config file: $KeysBaseDir/$keyname-conf.ovpn"

