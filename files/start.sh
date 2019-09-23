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
##
[ -z "$VPN_NETWORK" ] && { VPN_NETWORK="10.8.0.0/24"; }
[ -z "$NAT_RULE_AUTO" ] && { NAT_RULE_AUTO="no"; }
##
[ -z "$VPN_IS_DEFAULTGW" ] && { VPN_IS_DEFAULTGW="no"; }
##
[ -z "$IPV6_ADDRESS" ] && { IPV6_ADDRESS="disabled"; }
[ -z "$IPV6_VPN_IS_DEFAULTGW" ] && { IPV6_VPN_IS_DEFAULTGW="no"; }
[ -z "$IPV6_NAT_RULE_AUTO" ] && { IPV6_NAT_RULE_AUTO="no"; }
##
[ -z "$USE_IPTABLES_LEGACY" ] && { USE_IPTABLES_LEGACY="no"; }

# move client template conf to openvpn folder
if [ -e /etc/template-client.ovpn ] && [ $( diff /usr/share/doc/openvpn/examples/sample-config-files/client.conf /etc/openvpn/easy-rsa/templates/client.conf | wc -l ) -eq 0 ]
then
  echo "Updating client template file ..."
  mv /etc/template-client.ovpn /etc/openvpn/easy-rsa/templates/client.conf
fi

# Debian openvpn preconfig
ln -s -f /etc/openvpn/easy-rsa/openssl-1.0.0.cnf /etc/openvpn/easy-rsa/openssl.cnf
# server key expire time
[ -z $SERVER_KEY_EXPIRE ] && { SERVER_KEY_EXPIRE=3650; echo "Using default server key expire time: $SERVER_KEY_EXPIRE days"; }
# generate vpn server CA cert
if [ -e /etc/openvpn/easy-rsa/vars ] && [ ! -e /etc/openvpn/easy-rsa/pki/issued/vpnserver.crt ]
then
  echo "Generating server certs ..." 
  source /etc/openvpn/easy-rsa/vars
  cd /etc/openvpn/easy-rsa
  echo "Cleaning..."
  rm -rf /etc/openvpn/easy-rsa/pki
  echo "Creating server certification..."
  KEY_EXPIRE=$SERVER_KEY_EXPIRE
  CA_EXPIRE=$SERVER_KEY_EXPIRE
  export KEY_EXPIRE
  export CA_EXPIRE
  /etc/openvpn/easy-rsa/easyrsa init-pki
  /etc/openvpn/easy-rsa/easyrsa gen-dh
  echo -e "vpnserver\n" | /etc/openvpn/easy-rsa/easyrsa build-ca nopass
  /etc/openvpn/easy-rsa/easyrsa build-server-full vpnserver nopass
  openvpn --genkey --secret /etc/openvpn/ta.key
fi

echo "Checking revoke list..."
[ -e /etc/openvpn/crl.pem ] || touch /etc/openvpn/crl.pem

echo "Symlinking configs ..."
# new vpn with newer easyrsa
PKIDIR="/etc/openvpn/easy-rsa/pki"
[ -f $PKIDIR/dh.pem ] && { ln -f -s $PKIDIR/dh.pem /etc/openvpn/dh2048.pem; }
[ -f $PKIDIR/ca.crt ] && { ln -f -s $PKIDIR/ca.crt /etc/openvpn/ca.crt; }
[ -f $PKIDIR/issued/vpnserver.crt ] && { ln -f -s $PKIDIR/issued/vpnserver.crt /etc/openvpn/server.crt; }
[ -f $PKIDIR/private/vpnserver.key ] && { ln -f -s $PKIDIR/private/vpnserver.key /etc/openvpn/server.key; }
# common
[ -f $KEYDIR/crl.pem ] && { ln -f -s $KEYDIR/crl.pem /etc/openvpn/crl.pem; }
[ -d $KEYDIR/pki ] && { ln -f -s $KEYDIR/pki /etc/openvpn/easy-rsa/pki; }

# server address
# if SERVER_ADDRESS is not defined as sys Environment variable
#  the script try to get the public ip automatically
if [ -z $SERVER_ADDRESS ]
then
  # find public IP address
  PUBIP=$( curl -s -L -k http://ifconfig.co || exit 1 )
  # failsafe PUBIP
  [ $PUBIP ] || PUBIP=$( curl -L -k http://icanhazip.com || exit 1 )
  [ $PUBIP ] || PUBIP=$( curl -L -k http://ident.me || exit 1 )
  [ $PUBIP ] || PUBIP=$( curl -L -k http://eth0.me || exit 1 )
  if [ ! -z "$PUBIP" ]
  then
    SERVER_ADDRESS="$PUBIP"
    export SERVER_ADDRESS
    echo "SERVER_ADDRESS=$PUBIP" > /tmp/server_address.txt
    echo "Server address set to $PUBIP";
  fi
fi
# server IPv6 address
if [ $IPV6_ADDRESS == "auto" ]
then
  [ $( echo $SERVER_ADDRESS | fold -w1 | grep -i ":" | wc -l ) -gt 4 ] && { IS_IPV6=yes; } || { IS_IPV6=no; }
  if [ $IS_IPV6 == "yes" ]
  then
    IPV6_FULLADDRESS=$( ip addr | grep -i $SERVER_ADDRESS | awk '{ print $2 }' )
    subnetcalc $IPV6_FULLADDRESS > /dev/null || { echo "Error, Wrong IPv6 Subnet!"; exit 1; }
    echo "IPv6 address found: $IPV6_FULLADDRESS"
  else
    echo "IPv6 address not found, please define a valid address manually."
  fi
fi
if [ $( echo $IPV6_ADDRESS | fold -w1 | grep -i ":" | wc -l ) -gt 4 ]
then
  subnetcalc $IPV6_ADDRESS > /dev/null || { echo "Error, Wrong IPv6 Subnet!"; exit 1; }
  IPV6_FULLADDRESS=$IPV6_ADDRESS
fi
if [ ! -z $IPV6_FULLADDRESS ]
then
  echo "Updating server config with IPv6 address: $IPV6_FULLADDRESS ..."
  if [ $( grep -i server-ipv6 /etc/openvpn/server.conf | wc -l ) -gt 0 ]
  then
    sed -i "s@.*server-ipv6.*@server-ipv6 $IPV6_FULLADDRESS@g" /etc/openvpn/server.conf
  else
    echo "server-ipv6 $IPV6_FULLADDRESS" >> /etc/openvpn/server.conf
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

# VPN Network update
VPN_NET="$( echo $VPN_NETWORK | cut -f1 -d'/' )"
VPN_NET_MASK="$( ipcalc $VPN_NETWORK | grep -i netmask | awk '{ print $2 }' )"
if [ "$VPN_NET" ] && [ "$VPN_NET_MASK" ]
then
  echo "Updating server.conf ... set default VPN network to $VPN_NET $VPN_NET_MASK ..."
  sed -i -r 's@^server\ [0-9][0-9].*@server '$VPN_NET' '$VPN_NET_MASK'@g' /etc/openvpn/server.conf
fi

#if [ $( which iptables-legacy ) ]
if [ $USE_IPTABLES_LEGACY == "yes" ] || [ $USE_IPTABLES_LEGACY == "y" ] || [ $USE_IPTABLES_LEGACY == "1" ]
then
  IPTABLESCMD="iptables-legacy"
  echo "Using iptables-legacy command instead of default iptables command."
else
  IPTABLESCMD="iptables"
  echo "Using default iptables command."
fi 

# NAT rules
if [ $NAT_RULE_AUTO == "yes" ] || [ $NAT_RULE_AUTO == "y" ] || [ $NAT_RULE_AUTO == "1" ] || [ $NAT_RULE_AUTO == "true" ]
then
  echo "Deleting previous IPTABLES NAT rules ..."
  $IPTABLESCMD -D FORWARD -j ACCEPT
  for rulenumber in $( $IPTABLESCMD -t nat -L -n --line-numbers | grep -i "openvpn NAT rule" | awk '{ print $1 }' | sort -r -g | xargs )
  do
    echo "Deleting old NAT rule number $rulenumber ..."
    #iptables -t nat -D POSTROUTING -s $NETWORK -j MASQUERADE
    $IPTABLESCMD -t nat -D POSTROUTING $rulenumber
  done
  echo "Configuring IPTABLES NAT rules ..."
  $IPTABLESCMD -A FORWARD -j ACCEPT
  for NETWORK in $( cat /etc/openvpn/server.conf | egrep -i "^[server|route].*[1-9].*[1-9].*[1-9].*[1-9]" | grep -iv ':' | awk '{ print $2"/"$3 }' )
  do
    echo "Creating NAT rule for $NETWORK ..."
    $IPTABLESCMD -t nat -A POSTROUTING -s $NETWORK -j MASQUERADE -m comment --comment "openvpn NAT rule"
  done
fi
# NAT rules - IPv6
if [ $IPV6_NAT_RULE_AUTO == "yes" ] || [ $IPV6_NAT_RULE_AUTO == "y" ] || [ $IPV6_NAT_RULE_AUTO == "1" ] || [ $IPV6_NAT_RULE_AUTO == "true" ]
then
  echo "Deleting previous IPv6 NAT rules ..."
  ip6tables -D FORWARD -j ACCEPT
  for rulenumber in $( ip6tables -t nat -L -n --line-numbers | grep -i "openvpn NAT rule" | awk '{ print $1 }' | sort -r -g | xargs )
  do
    echo "Deleting old IPv6 NAT rule number $rulenumber ..."
    ip6tables -t nat -D POSTROUTING $rulenumber
  done
  echo "Configuring IPv6 NAT rules ..."
  ip6tables -A FORWARD -j ACCEPT
  IPV6_SUBNET=$( subnetcalc $IPV6_FULLADDRESS | grep -i Network | xargs | awk '{ print $3$4$5 }' )
  subnetcalc $IPV6_SUBNET > /dev/null || { echo "Error, Wrong IPv6 Subnet!"; exit 1; }
  ip6tables -t nat -A POSTROUTING -s $IPV6_SUBNET -j MASQUERADE -m comment --comment "openvpn NAT rule"
fi

# Default GW
if [ $VPN_IS_DEFAULTGW == "yes" ] || [ $VPN_IS_DEFAULTGW == "y" ] || [ $VPN_IS_DEFAULTGW == "1" ] || [ $VPN_IS_DEFAULTGW == "true" ]
then
  echo "Updating server.conf ... Set VPN GW to default GW ..."
  sed -i -r 's@.*push.*redirect-gateway@push "redirect-gateway@g' /etc/openvpn/server.conf
else
  echo "Updating server.conf ... Disable redirect-gateway-default GW funtion ..."
  sed -i -r 's@.*push.*redirect-gateway@#push "redirect-gateway@g' /etc/openvpn/server.conf
fi
# Default GW - IPv6
if [ $( egrep -i push.*route-ipv6.*::/0 /etc/openvpn/server.conf | wc -l ) -eq 0 ]
then
  echo '# push "route-ipv6 ::/0" # route all ipv6 traffic through the tunnel' >>  /etc/openvpn/server.conf
fi
if [ $IPV6_VPN_IS_DEFAULTGW == "yes" ] || [ $IPV6_VPN_IS_DEFAULTGW == "y" ] || [ $IPV6_VPN_IS_DEFAULTGW == "1" ] || [ $IPV6_VPN_IS_DEFAULTGW == "true" ]
then
  echo "Updating server.conf ... Set VPN GW to default GW for IPv6 ..."
  sed -i -r 's@.*push.*route-ipv6.*::/0@push "route-ipv6 ::/0@g' /etc/openvpn/server.conf
else
  echo "Updating server.conf ... Disable redirect-gateway-default GW funtion for IPv6 ..."
  sed -i -r 's@.*push.*route-ipv6.*::/0@#push "route-ipv6 ::/0@g' /etc/openvpn/server.conf
fi

# tls-auth enable in server.conf
sed -i 's@.*tls-auth@tls-auth@g' /etc/openvpn/server.conf

# client-config-dir for clients with fixed IP addresses
FIX_IP_DIR="$( egrep -i "^client-config-dir" /etc/openvpn/server.conf | awk '{ print $2 }' )"
if [ ! -z $FIX_IP_DIR ]
then
  echo "Creating client-config-dir: $FIX_IP_DIR"
  mkdir -p "/etc/openvpn/$( echo $FIX_IP_DIR | sed s@/etc/openvpn/@@g )"
  [ -d /etc/openvpn/$FIX_IP_DIR ] || { echo "Something wrong. Please create the client-config-dir manually"; }
fi

# Radius server conf
if [ $RADIUS_SERVER ] && [ $RADIUS_SECRET ]
then
  echo "$RADIUS_SERVER  $RADIUS_SECRET  1" > /etc/openvpn/pam_radius_auth.conf
fi
[ ! -f /etc/openvpn/pam_radius_auth.conf ] && { echo "RADIUS_SERVER  RADIUS_SECRET  1" > /etc/openvpn/pam_radius_auth.conf; }
[ -e /etc/openvpn/pam_radius_auth.conf ] && { ln -s -f /etc/openvpn/pam_radius_auth.conf /etc/pam_radius_auth.conf; }
[ -e /etc/pam_openvpn ] && [ ! -e /etc/openvpn/pam_openvpn ] && { mv /etc/pam_openvpn /etc/openvpn/pam_openvpn; }
[ -e /etc/openvpn/pam_openvpn ] && { ln -s -f /etc/openvpn/pam_openvpn /etc/pam.d/openvpn; }

# Revoked cert check
if [ $( grep -i crl-verify /etc/openvpn/server.conf | wc -l ) -eq 0 ]
then
  echo -e "\n# enable revoked cert check mechanism" >> /etc/openvpn/server.conf
  echo ";crl-verify crl.pem" >> /etc/openvpn/server.conf
fi

# Default INFO
echo "Check and modify the server.conf file manually for more complex setup! Like routing, DNS and etc..."
echo "But do not forget restart the container after that!"

# debug - list all sys variables
#set

# Start Openvpn
cd /etc/openvpn && openvpn --config server.conf
#tail -f /dev/null

# END
