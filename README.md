# Docker OpenVPN container

## Build

Please configure your vpn key data (company, domain, email, etc...) in the `files/openvpn-vars` file before you run the build.

```
docker build -t my/ovpn .
```

## Run

```
docker run -tid --privileged --name=openvpn -p 1194:1194/udp -p 1194:1194/tcp -v /srv/ovpn/config:/etc/openvpn my/ovpn /opt/start.sh
```

The `--privileged` parameter is very important! The openvpn container uses the tun/tap interface on your host.


After first run you got many config files in the `/srv/ovpn/config` and `/srv/ovpn/config/easy-rsa` folder on your host. You have to change these config files to personalize your config.

  - server.conf
  - client.conf
  - vars

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

