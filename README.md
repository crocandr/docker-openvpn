# Docker OpenVPN container

## Build

```
docker build -t croc/openvpn .
```

## Host config

Forward an UDP port from your router to the docker host that runs this OpenVPN container.
Default UDP port is 1194, but you can choose 21194, 51194 or any other port.

You have to load tun module into the docker host kernel if not loaded by default:

```
modprobe tun
```

The IP forward is enabled in docker by default. But please check it and enable if necessary.

```
cat /proc/sys/net/ipv4/ip_forward
1
```

If the `ip_forward` is not `1`, please enable with this command (example):

```
echo 1 > /proc/sys/net/ipv4/ip_forward
```

You can enable this in the sysctl config file of your system, but the docker turns on this ip forward by default.

The most important step:
You **have to** enable NAT rule on the docker's host for VPN's network if you don't use the NAT_RULE_AUTO option for this!
The VPN network is `10.8.0.0/24` by default.

example:
```
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -j MASQUERADE
```

## Run

You have to run the OpenVPN container in `privileged` with `host network` mode.

Recommended way is docker-compose!

### Docker run

```
docker run -t --privileged --name=openvpn --net=host -e SERVER_PORT=51194 -v /srv/openvpn/config:/etc/openvpn croc/openvpn
```

  - The `--privileged` parameter is very important! The OpenVPN container uses the tun/tap interface on your host.
  - You can use the docker host's iptables (too) with `--net=host`
  - You can use these extra parameters too:
      - `SERVER_ADDRESS=vpn.myvpn-domain.com` (optional) - the public address of your vpn server, your clients will use this address to connect your server, if you don't define this, the container tries to get your actual public IP address by default
      - `SERVER_PORT=51194` - the OpenVPN service listen port
      - `PROTO=udp` (optional) - server protocol: `udp` (default) or `tcp`
      - `KEY_COUNTRY=HU` - certificate key data
      - `KEY_PROVINCE=HU` - certificate key data
      - `KEY_CITY=Budapest` - certificate key data
      - `KEY_ORG=My Tech Company` - certificate key data
      - `KEY_EMAIL=vpn@my-tech-company.com` - certificate key data
      - `KEY_OU=IT NETWORK` - certificate key data
      - `NAT_RULE_AUTO=yes` (optional) - set the IPTABLES NAT rules automatically if you run with `network_mode: "host"` option (enable: 1,y,yes ; disable: false,0,n,no). This feature is disabled by default.
      - `VPN_NETWORK=10.88.77.0/24` (optional) - you can modify the default VPN network. This is useful with NAT_RULE_AUTO option.
      - `VPN_IS_DEFAULTGW=yes` (optional) - you can set the VPN host as default GW on every connected clients. All traffic will go through the VPN such as web browsing, dns querries, etc.
      - `IPV6_ADDRESS=2a03:b0c0:3:d0::1991:1/112` - your IPv6 subnet for VPN clients (please use smaller subnet than your OpenVPN server have by default). You can use `auto` option instead of a host address with CIDR, but with `auto` option OpenVPN use the server default IPv6 address/network.
      - `IPV6_NAT_RULE_AUTO=yes` (optional, but recommended) - same like IPv4 but good option if your clients do not have IPv6 addresses
      - `IPV6_VPN_IS_DEFAULTGW=yes` (optional, but recommended) - VPN host as default GW for connected clients for IPv6 network

### Docker-compose

```
docker-compose up -d
```

I highly recommend to use the docker-compose file. This docker-compose method contains the latest updates, parameters, and other recommended configurations. .... and much easier to start the VPN server :)

Optional Radius connection parameter:
  - `-e RADIUS_SERVER=127.0.0.1` and `-e RADIUS_SECRET=secret` - for radius authentication. Check my Wiki page on Github for more information.

After first run you will get many config files in the `openvpn/config` and `openvpn/config/easy-rsa` folder on your host. You have to change these config files to personalize your config.

  - server.conf
  - client.conf (in `easy-rsa/templates` folder)


## OpenVPN config

You can modify the default config for your network in the openvpn's config file on your Docker host.
You can add routes, etc... Example:

`vi config/server.conf`:

```
...
push "route 192.168.0.0 255.255.255.0"
push "route 172.0.1.0 255.255.255.0"
;push "route 192.168.10.0 255.255.255.0"
...
```

If you modified the server.conf file, please restart the OpenVPN container:

```
docker restart openvpn
```
or
```
docker-compose restart
```

## Generate client cert

You can generate a cert for a client with these commands.

You need connect to the container, generate and disconnect:

```
docker exec -ti openvpn /opt/generate-newclient-cert.sh user1
```

This cert generator script uses the `client.conf` file as a template, and integrate the generated cert files into the client config file. So you can use only one file for the OpenVPN. Only the opvn config file. (example: user1-conf.ovpn ).  
You can access the generated config (and cert files too) in the `/srv/openvpn/config/easy-rsa/keys/` folder on your Docker host.

Optional:

  1. You can copy the keys to a readable directory:
```
cp /srv/openvpn/config/easy-rsa/keys/*.ovpn /tmp
```
  2. You can modify the permission of the key file:
```
chmod 755 /srv/openvpn/config/easy-rsa/keys
```

## Revoke a client cert

You can revoke a client cert with a simple script.

version A - with cert name only:
```
docker exec -ti openvpn /opt/revoke-client-cert.sh user1 
```

version B - with full path of cert:
```
docker exec -ti openvpn /opt/revoke-client-cert.sh /etc/openvpn/easy-rsa/keys/user1.crt 
```

### Config

You have to enable the revoked cert checking mechanism in your `server.conf` file with this line:
```
crl-verify crl.pem
```

**Good to know**:

If you enable this option, you have to generate and revoke a cert (example: test or anything).
Because the clients can't connect if you don't have a valid `crl.pem` file. Empty crl.pem is not valid crl.pem file! (This is an OpenVPN bug?)

## Old client certificates

You can list old client keys with a simple script.

```
docker exec -ti openvpn /opt/list-old-keys.sh
```

If the client cert's last day is coming, You should generate a new client key/cert/config for the client.

## Additional configuration

You can use extra authentication methods for this vpn container. Like:

  - user and password pair from a Radius server
  - user and google authentication key as password
  - user and password with google authentication key as password

Please check my Github Wiki page for additional information and configuration examples:
  - https://github.com/crocandr/docker-openvpn/wiki




Good Luck!
