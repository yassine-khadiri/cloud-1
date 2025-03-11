#!/bin/sh

# apt-get install -y openssl && \
#     openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout \
#     /etc/ssl/private/nginx-selfsigned.key \
#     -out /etc/ssl/certs/nginx-selfsigned.crt \
#     -subj="/CN=ykhadiri/O=ykhadiri.1337.ma/C=MA/L=KHOURIBGA"
mkdir -p /etc/nginx/ssl/
# openssl req -newkey rsa:2048 -x509 -nodes -days 365  \
#     -keyout /etc/nginx/ssl/private.key \
#     -out /etc/nginx/ssl/certificate.crt \
#     -subj "/C=MO/ST=KO/L=KO/O=42/CN=42.fr"



# echo hello from nginx-init.sh

# nginx -g 'daemon off;'