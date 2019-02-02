FROM debian 

RUN apt-get update && apt-get install -y net-tools less curl vim tar gzip ruby openvpn easy-rsa iptables libpam-google-authenticator libpam-radius-auth freeradius-utils ipcalc sipcalc 

COPY files/template-client.ovpn /etc/
COPY files/openvpn-vars /etc/
COPY files/*.sh /opt/
COPY files/tools /opt/
# Radius conf preparation
COPY files/pam_openvpn /etc/ 
# scripts - permission change
RUN chmod +x /opt/*.sh /opt/*.rb

COPY files/start.sh /opt/start.sh
RUN chmod +x /opt/start.sh

ENTRYPOINT /opt/start.sh
