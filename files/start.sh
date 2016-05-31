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

if [ -e /etc/openvpn-vars ]
then
  mv /etc/openvpn-vars /etc/openvpn/easy-rsa/vars
fi
if [ -e /etc/template-client.ovpn ]
then
  mv /etc/template-client.ovpn /etc/openvpn/easy-rsa/templates/client.conf
fi


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

echo "Symlinking configs ..."
ln -f -s /etc/openvpn/easy-rsa/keys/ca.crt /etc/openvpn/ca.crt
ln -f -s /etc/openvpn/easy-rsa/keys/vpnserver.crt /etc/openvpn/server.crt
ln -f -s /etc/openvpn/easy-rsa/keys/vpnserver.key /etc/openvpn/server.key

# Start Openvpn
cd /etc/openvpn && openvpn --config server.conf



# END
#/bin/bash

