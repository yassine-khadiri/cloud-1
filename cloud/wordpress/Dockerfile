# Use the official WordPress image as base image
FROM wordpress:6.7.2-php8.4-fpm

# Set Working diretory
WORKDIR /var/www/html/

# Copy wp-init.sh file into the container, set permission
COPY ./tools/wp-init.sh /tmp/wp-init.sh
RUN chmod +x /tmp/wp-init.sh

# Expose port 9000 for PHP-FPM
EXPOSE 9000

# Set the entrypoint
ENTRYPOINT ["sh", "-c", "docker-entrypoint.sh php-fpm & sleep 10 && /tmp/wp-init.sh && wait"]