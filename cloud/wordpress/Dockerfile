# Use the official WordPress image as base image
FROM wordpress:6.7.2-php8.4-fpm

# Set Working diretory
WORKDIR /var/www/html/

# Copy WordPress files from the base image to the working directory
COPY --from=wordpress:6.7.2-php8.4-fpm /usr/src/wordpress/ /var/www/html/

# Copy wp-init.sh file into the container, set permission
# and execute it

COPY ./tools/wp-init.sh /tmp/wp-init.sh
RUN chmod +x /tmp/wp-init.sh
# RUN /tmp/wp-init.sh

# Expose port 9000 for PHP-FPM
EXPOSE 9000

# ENTRYPOINT ["/tmp/wp-init.sh"]
CMD ["sh", "-c", "docker-entrypoint.sh php-fpm & sleep 10 && /tmp/wp-init.sh && wait"]
