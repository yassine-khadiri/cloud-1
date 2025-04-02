FROM nginx:1.25-alpine

RUN apk add --no-cache openssl \
    && mkdir -p /etc/nginx/ssl \
    && openssl req -newkey rsa:2048 -x509 -nodes -days 365 \
       -keyout /etc/nginx/ssl/private.key \
       -out /etc/nginx/ssl/certificate.crt \
       -subj "/C=MO/ST=KO/L=KO/O=42/CN=42.fr"

COPY conf/default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80 443

CMD [ "nginx", "-g", "daemon off;" ]
