#!/bin/sh

WP_CLI_PATH="/usr/local/bin/wp"

if [ ! -f /var/www/html/wp-config.php ]; then
    cp wp-config-sample.php wp-config.php
fi

if [ ! -f "$WP_CLI_PATH" ]; then
    curl -o "$WP_CLI_PATH" https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x "$WP_CLI_PATH"
fi

chmod 777 /var/www/html

wp config set --allow-root DB_NAME $MYSQL_DATABASE
wp config set --allow-root DB_USER $MYSQL_USER
wp config set --allow-root DB_PASSWORD $MYSQL_PASSWORD
wp config set --allow-root DB_HOST $MYSQL_HOST
wp config set --allow-root WP_HOME "https://$DOMAIN_NAME"
wp config set --allow-root WP_SITEURL "https://$DOMAIN_NAME"

# Check if WordPress is already installed
if ! wp core is-installed --allow-root; then
    echo "Installing WordPress core..."
    wp core install \
        --url="$DOMAIN_NAME" \
        --title="My Automated WordPress Site" \
        --admin_user="$ADMIN_USER" \
        --admin_password="$ADMIN_PASSWORD" \
        --admin_email="$ADMIN_EMAIL" \
        --skip-email \
        --allow-root

    echo "Creating additional user..."
    wp core update --allow-root && \
    wp core update-db --allow-root && \
    wp user create \
        --allow-root \
        "$WP_USER" \
        "$WP_USER_EMAIL" \
        --user_pass="$WP_USER_PASSWORD" \
        --role=editor
    
    # echo "Installing and activating Astra theme..."
    # wp theme install --allow-root astra --activate
else
    echo "WordPress is already installed."
fi