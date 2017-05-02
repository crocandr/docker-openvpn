# Docker OpenVPN container

## Build

Please configure your vpn key data (company, domain, email, etc...) in the `files/openvpn-vars` file before you run the build.

```
docker build -t croc/openvpn .
```
## Host config

Enable UDP 1194 port for OpenVPN.

You have to load tun modul into the host kernel if not loaded by default:

```
modprobe tun
```

The ip forward is enabled in docker by default. But please check it and enable if nessesarry.

```
cat /proc/sys/net/ipv4/ip_forward
1
```

If the `ip_forward` is not `1`, please enable with this command (example):

```
echo 1 > /proc/sys/net/ipv4/ip_forward
```

You **have to** enable NAT rule on the docker's host for VPN's network.  
The VPN network is `10.8.0.0/24` by default.

```
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -j MASQUERADE
```

## Run

You have to run the openvpn's container in `privileged` with `host network` mode.

```
docker run -tid --privileged --name=openvpn --net=host -v /srv/ovpn/config:/etc/openvpn croc/openvpn /opt/start.sh
```

  - The `--privileged` parameter is very important! The openvpn container uses the tun/tap interface on your host.
  - You can use the docker host's iptables (too) with `--net=host`
  - The container find the public IP address automatically, but You can define a custom IP/hostname for `remote` server address for the clients with the `-e ServerAddress=myserver.mynet.com` parameter. This remote addess use by the client config.

After first run you got many config files in the `/srv/ovpn/config` and `/srv/ovpn/config/easy-rsa` folder on your host. You have to change these config files to personalize your config.

  - server.conf
  - client.conf
  - vars


## OpenVPN config

You have to **modify** default config for your network in the openvpn's config file on your Docker host.
You have to add routes, etc... Example:

`nano /srv/ovpn/config/server.conf`:

```
...
push "route 192.168.0.0 255.255.255.0"
push "route 172.0.1.0 255.255.255.0"
;push "route 192.168.10.0 255.255.255.0"
...
```

If you modified the server.conf file, please restart the openvpn container:

```
docker restart openvpn
```

## Generate client cert

You can genereate cert for clients with these commands.

You need connect to the container, generate and disconnect:

```
docker exec -ti openvpn /bin/bash
/opt/generate-newclient-cert.sh user1
exit
```

This cert generator script uses the `client.conf` file as a template, and integrate the generated cert files into the client config file. So you can use only one file for the openvpn. Only the opvn config file. (example: user1-conf.ovpn ).  
You can access the generated config (and cert files too) in the `/srv/ovpn/config/easy-rsa/keys/` folder on your Docker host.

Optional:
You can copy the keys to a readable directory:
```
cp /srv/ovpn/config/easy-rsa/keys/*.ovpn /tmp
```
Notes: You must copy these files if you are in AWS environment because the *keys* folder is not readable by ubuntu user. After the copy, you can download with scp command: 
```
scp -i key.pem ubuntu@public_ip:/tmp/*.ovpn .
```

## Revoke a client cert

You can revoke a client cert with a simple script.

version A - with cert name only:
```
docker exec -ti openvpn /bin/bash
./revoke-client-cert.sh user1 
exit
```

version B - with full path of cert:
```
docker exec -ti openvpn /bin/bash
./revoke-client-cert.sh /etc/openvpn/easy-rsa/keys/user1.crt
exit
```

### Config

You have to enable the revoked cert checking mechanism in your `server.conf` file with this line:
```
crl-verify crl.pem
```

**Good to know**:

If you enable this option, you have to generate and revoke a cert (example: test or anything).
Because the clients can't connect if you don't have a valid `crl.pem` file. Empty crl.pem is not valid crl.pem file. (This is an OpenVPN bug?)

## Old client certificates

You can list old client keys with a simple script.

```
docker exec -ti openvpn /opt/list-old-keys.sh
```

If the client cert's last day is coming, You should generate a new client key/cert/config for the client.





Good Luck!
