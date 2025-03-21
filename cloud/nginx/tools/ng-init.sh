#!/bin/sh

mkdir -p /etc/nginx/ssl/

openssl req -newkey rsa:2048 -x509 -nodes -days 365  \
    -keyout /etc/nginx/ssl/private.key \
    -out /etc/nginx/ssl/certificate.crt \
    -subj "/C=MO/ST=KO/L=KO/O=42/CN=42.fr"

cp /tmp/default.conf /etc/nginx/conf.d/default.conf
nginx -s reload
