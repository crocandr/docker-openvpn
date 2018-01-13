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

if [ ! -e /etc/openvpn/dh2048.pem ]
then
  echo "Generating a cert ..."
  openssl dhparam -out /etc/openvpn/dh2048.pem 2048
fi

# move openvpn-vars to openvpn folder
if [ -e /etc/openvpn-vars ]
then
  mv /etc/openvpn-vars /etc/openvpn/easy-rsa/vars
fi
# move client template conf to openvpn folder
if [ -e /etc/template-client.ovpn ] && [ $( diff /usr/share/doc/openvpn/examples/sample-config-files/client.conf /etc/openvpn/easy-rsa/templates/client.conf | wc -l ) -eq 0 ]
then
  echo "Updating client template file ..."
  mv /etc/template-client.ovpn /etc/openvpn/easy-rsa/templates/client.conf
fi

# generate vpn server CA cert
if [ -e /etc/openvpn/easy-rsa/vars ] && [ ! -e /etc/openvpn/easy-rsa/keys/vpnserver.crt ]
then
  echo "Generating server certs ..." 
  source /etc/openvpn/easy-rsa/vars
  cd /etc/openvpn/easy-rsa
  ./clean-all
  cd /etc/openvpn/easy-rsa/keys
  ../pkitool --initca vpnserver
  ../pkitool --server vpnserver
fi

echo "Checking revoke list..."
[ -e /etc/openvpn/easy-rsa/keys/crl.pem ] || touch /etc/openvpn/easy-rsa/keys/crl.pem

echo "Symlinking configs ..."
ln -f -s /etc/openvpn/easy-rsa/keys/ca.crt /etc/openvpn/ca.crt
ln -f -s /etc/openvpn/easy-rsa/keys/vpnserver.crt /etc/openvpn/server.crt
ln -f -s /etc/openvpn/easy-rsa/keys/vpnserver.key /etc/openvpn/server.key
ln -f -s /etc/openvpn/easy-rsa/keys/crl.pem /etc/openvpn/crl.pem

# server port update
[ -z $ServerPort ] && { $ServerPort=1194; echo "Server port set to default"; }
echo "Updating server.conf ... set listen port to $ServerPort ..."
sed -i -e "s@^[pP]ort.*@port $ServerPort@g" /etc/openvpn/server.conf

# Radius server conf
if [ $RADIUS_SERVER ] && [ $RADIUS_SECRET ]
then
  echo "$RADIUS_SERVER  $RADIUS_SECRET  1" > /etc/openvpn/pam_radius_auth.conf
fi
[ ! -f /etc/openvpn/pam_radius_auth.conf ] && { echo "RADIUS_SERVER  RADIUS_SECRET  1" > /etc/openvpn/pam_radius_auth.conf; }
[ -e /etc/openvpn/pam_radius_auth.conf ] && { ln -s -f /etc/openvpn/pam_radius_auth.conf /etc/pam_radius_auth.conf; }
[ -e /etc/pam_openvpn ] && [ ! -e /etc/openvpn/pam_openvpn ] && mv /etc/pam_openvpn /etc/openvpn/pam_openvpn
[ -e /etc/openvpn/pam_openvpn ] && ln -s -f /etc/openvpn/pam_openvpn /etc/pam.d/openvpn

# Start Openvpn
cd /etc/openvpn && openvpn --config server.conf


# END
#/bin/bash

