FROM ubuntu:xenial

RUN apt-get update && apt-get install -y net-tools less curl vim tar gzip openvpn easy-rsa

COPY files/template-client.ovpn /etc/
COPY files/openvpn-vars /etc/
COPY files/generate-newclient-cert.sh /opt/
COPY files/revoke-client-cert.sh /opt/
COPY files/list-old-keys.sh /opt/
RUN chmod +x /opt/*.sh

COPY files/start.sh /opt/start.sh
RUN chmod +x /opt/start.sh

