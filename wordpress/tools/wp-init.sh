#!/bin/sh

# sed -i 's/max_execution_time = 30/max_execution_time = 300/' /etc/php/7.3/fpm/php.ini
wordpress_path="/var/www/html/"
if [  -f /var/www/html/wp-config.php ]; then
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar

    chmod +x wp-cli.phar

    mv wp-cli.phar /usr/local/bin/wp

    cd /var/www/html

    chmod 777 /var/www/html

    wp core download --allow-root

    # cp wp-config-sample.php wp-config.php

    wp config set --allow-root DB_NAME $WORDPRESS_DB_NAME
    wp config set --allow-root DB_USER $WORDPRESS_DB_USER
    wp config set --allow-root DB_PASSWORD $WORDPRESS_DB_PASSWORD
    wp config set --allow-root DB_HOST $WORDPRESS_DB_HOST

    # sed -i "s/wordpress/${WORDPRESS_DB_NAME}/g"  "$wordpress_path/wp-config.php"
    # sed -i "s/example username/${WORDPRESS_DB_USER}/g" "$wordpress_path/wp-config.php"
    # sed -i "s/example password/${WORDPRESS_DB_PASSWORD}/g" "$wordpress_path/wp-config.php"
    # sed -i "s/localhost/mariadb/g" "$wordpress_path/wp-config.php"

    wp core install \
        --url=$DOMAIN_NAME \
        --title="My Automated WordPress Site" \
        --admin_user=$ADMIN_USER \
        --admin_password=$ADMIN_PASSWORD\
        --admin_email=$ADMIN_EMAIL \
        --skip-email \
        --allow-root

    wp user create --allow-root $WORDPRESS_DB_USER $WORDPRESS_DB_USER_MAIL --user_pass=$WORDPRESS_DB_USER

fi
