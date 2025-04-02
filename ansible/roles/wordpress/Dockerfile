
FROM wordpress:6.3-php8.2-fpm-alpine

WORKDIR /var/www/html/

COPY ./tools/wp-init.sh /tmp/wp-init.sh
RUN chmod +x /tmp/wp-init.sh

ENTRYPOINT ["sh", "-c", "docker-entrypoint.sh php-fpm & sleep 10 && /tmp/wp-init.sh && wait"]