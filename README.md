# Docker OpenVPN container

## Build

Please configure your vpn key data (company, domain, email, etc...) in the `files/openvpn-vars` file before you run the build.

```
docker build -t my/ovpn .
```

## Run

You have to run the openvpn's container in `privileged` with `host network` mode.

```
docker run -tid --privileged --name=openvpn --net=host -v /srv/ovpn/config:/etc/openvpn sonrisa/open
vpn /opt/start.sh
```

  - The `--privileged` parameter is very important! The openvpn container uses the tun/tap interface on your host.
  - You can use the docker host's iptables (too) with `--net=host`


After first run you got many config files in the `/srv/ovpn/config` and `/srv/ovpn/config/easy-rsa` folder on your host. You have to change these config files to personalize your config.

  - server.conf
  - client.conf
  - vars

## Host config

The ip forward is enabled in docker by default. But please check it and enable if nessesarry.

```
cat /proc/sys/net/ipv4/ip_forward
1
```

If the `ip_forward` is not `1`, please enable with this command (example):

```
echo 1 > /proc/sys/net/ipv4/ip_forward
```

You have to enable NAT rule on the docker's host for VPN's network.  
The VPN network is `10.8.0.0/24` by default.

```
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -j MASQUERADE
```

## Generate client cert

You can genereate cert for clients with these commands.

You need connect to the container, generate and disconnect:

```
docker exec -ti openvpn /bin/bash
/opt/generate-newclient-cert.sh user1
exit
```

...**or** simple exec the generate script:

```
docker exec -ti openvpn /opt/generate-newclient-cert.sh user1
```

This cert generator script uses the `client.conf` file as a template, and integrate the generated cert files into the client config file. So you can use only one file for the openvpn. Only the opvn config file. (example: user1-conf.ovpn ).  
You can access the generated config (and cert files too) in the `/srv/ovpn/config/easy-rsa/keys/` folder on your Docker host.

