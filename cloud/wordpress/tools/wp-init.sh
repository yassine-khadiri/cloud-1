#!/bin/sh

set -e

# Set listening port
sed -i 's/^listen = 127.0.0.1:9000/listen = 9000/' /usr/local/etc/php-fpm.d/www.conf

# go to the WordPress directory
# cd /var/www/html


# Install WP-CLI
wp_cli_path="/usr/local/bin/wp"
if [ ! -f "$wp_cli_path" ]; then
    # Download WP-CLI
    curl -o "$wp_cli_path" https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x "$wp_cli_path"
fi

# Check if WordPress Configuration file exists
if [ ! -f /var/www/html/wp-config.php ]; then
    # Create a new WordPress Configuration file
    cp wp-config-sample.php wp-config.php
    # wp core download --allow-root --path=/var/www/html
    # wp config create --allow-root 
fi

# Set WordPress configuration
wp config set --allow-root DB_NAME $WORDPRESS_DB_NAME
wp config set --allow-root DB_USER $WORDPRESS_DB_USER
wp config set --allow-root DB_PASSWORD $WORDPRESS_DB_PASSWORD
wp config set --allow-root DB_HOST $WORDPRESS_DB_HOST
wp config set --allow-root WP_HOME "https://$DOMAIN_NAME"
wp config set --allow-root WP_SITEURL "https://$DOMAIN_NAME"

# Check if WordPress is installed
if ! wp core is-installed --allow-root; then
    # Install WordPress
    wp core install \
    --url="https://$DOMAIN_NAME" \
    --title="My Automated WordPress Site" \
    --admin_user="$ADMIN_USER" \
    --admin_password="$ADMIN_PASSWORD" \
    --admin_email="$ADMIN_EMAIL" \
    --skip-email \
    --allow-root

    # Update WordPress and create a new user
    wp core update --allow-root && \
    wp core update-db --allow-root && \
    wp user create \
    --allow-root \
    "$WORDPRESS_DB_USER" \
    "$WORDPRESS_DB_USER_MAIL" \
    --user_pass="$WORDPRESS_DB_PASSWORD" \
    --role=editor

    # Install theme
    wp theme install inspiro --activate --allow-root
fi

# exec "$@"
