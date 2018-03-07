#!/bin/bash

# OpenVPN config
if [ ! -d /etc/openvpn ]
then
  exit -1
fi

if [ ! -e /etc/openvpn/server.conf ]
then
  echo "Generating basic configuration..."
  gunzip -c /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz > /etc/openvpn/server.conf
  cp -rf /usr/share/easy-rsa/ /etc/openvpn/
  mkdir /etc/openvpn/easy-rsa/keys

  mkdir /etc/openvpn/easy-rsa/templates
  cp -f /usr/share/doc/openvpn/examples/sample-config-files/client.conf /etc/openvpn/easy-rsa/templates
fi

# move openvpn-vars to openvpn folder
if [ -e /etc/openvpn-vars ]
then
  mv /etc/openvpn-vars /etc/openvpn/easy-rsa/vars
fi
## key data
[ -z "$KEY_COUNTRY" ] && { KEY_COUNTRY="HU"; }
[ -z "$KEY_PROVINCE" ] && { KEY_PROVINCE="HU"; }
[ -z "$KEY_CITY" ] && { KEY_CITY="Budapest"; }
[ -z "$KEY_ORG" ] && { KEY_ORG="My Company"; }
[ -z "$KEY_EMAIL" ] && { KEY_EMAIL="vpn@mycompany.com"; }
[ -z "$KEY_OU" ] && { KEY_OU="IT"; }

# move client template conf to openvpn folder
if [ -e /etc/template-client.ovpn ] && [ $( diff /usr/share/doc/openvpn/examples/sample-config-files/client.conf /etc/openvpn/easy-rsa/templates/client.conf | wc -l ) -eq 0 ]
then
  echo "Updating client template file ..."
  mv /etc/template-client.ovpn /etc/openvpn/easy-rsa/templates/client.conf
fi

# server key expire time
[ -z $SERVER_KEY_EXPIRE ] && { SERVER_KEY_EXPIRE=3650; echo "Using default server key expire time: $SERVER_KEY_EXPIRE days"; }
# generate vpn server CA cert
if [ -e /etc/openvpn/easy-rsa/vars ] && [ ! -e /etc/openvpn/easy-rsa/keys/vpnserver.crt ]
then
  echo "Generating server certs ..." 
  source /etc/openvpn/easy-rsa/vars
  cd /etc/openvpn/easy-rsa
  ./clean-all
  cd /etc/openvpn/easy-rsa/keys
  KEY_EXPIRE=$SERVER_KEY_EXPIRE
  CA_EXPIRE=$SERVER_KEY_EXPIRE
  export KEY_EXPIRE
  export CA_EXPIRE
  ../build-dh
  ../pkitool --initca
  ../pkitool --server vpnserver
fi

echo "Checking revoke list..."
[ -e /etc/openvpn/easy-rsa/keys/crl.pem ] || touch /etc/openvpn/easy-rsa/keys/crl.pem

echo "Symlinking configs ..."
ln -f -s /etc/openvpn/easy-rsa/keys/dh2048.pem /etc/openvpn/dh2048.pem
ln -f -s /etc/openvpn/easy-rsa/keys/ca.crt /etc/openvpn/ca.crt
ln -f -s /etc/openvpn/easy-rsa/keys/vpnserver.crt /etc/openvpn/server.crt
ln -f -s /etc/openvpn/easy-rsa/keys/vpnserver.key /etc/openvpn/server.key
ln -f -s /etc/openvpn/easy-rsa/keys/crl.pem /etc/openvpn/crl.pem

# server address
# if SERVER_ADDRESS is not defined as sys Environment variable
#  the script try to get the public ip automatically
if [ -z $SERVER_ADDRESS ]
then
  # find public IP address
  PUBIP=$( curl -L -k http://ifconfig.co || exit 1 )
  # failsafe PUBIP
  [ $PUBIP ] || PUBIP=$( curl -L -k http://icanhazip.com || exit 1 )
  [ $PUBIP ] || PUBIP=$( curl -L -k http://ident.me || exit 1 )
  [ $PUBIP ] || PUBIP=$( curl -L -k http://eth0.me || exit 1 )
  if [ ! -z "$PUBIP" ]
  then
    SERVER_ADDRESS="$PUBIP"
    echo "Server address set to $PUBIP";
  fi
fi
# server port update
[ -z $SERVER_PORT ] && { SERVER_PORT=1194; echo "Server port set to default: $SERVER_PORT"; }
echo "Updating server.conf ... set listen port to $SERVER_PORT ..."
sed -i -e "s@^[pP]ort.*@port $SERVER_PORT@g" /etc/openvpn/server.conf
# server protocol update
[ -z $PROTO ] && { PROTO=udp; echo "Server protocol mode set to default: $PROTO"; }
sed -i -e "s@^[pP]roto.*@proto $PROTO@g" /etc/openvpn/server.conf
# disable deprecated functions
sed -i -e "s@^comp-lzo.*@;comp-lzo@g" /etc/openvpn/server.conf


# Radius server conf
if [ $RADIUS_SERVER ] && [ $RADIUS_SECRET ]
then
  echo "$RADIUS_SERVER  $RADIUS_SECRET  1" > /etc/openvpn/pam_radius_auth.conf
fi
[ ! -f /etc/openvpn/pam_radius_auth.conf ] && { echo "RADIUS_SERVER  RADIUS_SECRET  1" > /etc/openvpn/pam_radius_auth.conf; }
[ -e /etc/openvpn/pam_radius_auth.conf ] && { ln -s -f /etc/openvpn/pam_radius_auth.conf /etc/pam_radius_auth.conf; }
[ -e /etc/pam_openvpn ] && [ ! -e /etc/openvpn/pam_openvpn ] && { mv /etc/pam_openvpn /etc/openvpn/pam_openvpn; }
[ -e /etc/openvpn/pam_openvpn ] && { ln -s -f /etc/openvpn/pam_openvpn /etc/pam.d/openvpn; }

# debug - list all sys variables
#set

# Start Openvpn
cd /etc/openvpn && openvpn --config server.conf

# END
