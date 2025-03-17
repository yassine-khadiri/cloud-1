#!/bin/sh

if [  -f /var/www/html/wp-config.php ]; then
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar

    chmod +x wp-cli.phar

    mv wp-cli.phar /usr/local/bin/wp

    cd /var/www/html

    chmod 777 /var/www/html

    wp core download --allow-root

    wp config set --allow-root DB_NAME $WORDPRESS_DB_NAME
    wp config set --allow-root DB_USER $WORDPRESS_DB_USER
    wp config set --allow-root DB_PASSWORD $WORDPRESS_DB_PASSWORD
    wp config set --allow-root DB_HOST $WORDPRESS_DB_HOST

    # wp core install \
    #     --url=$DOMAIN_NAME \
    #     --title="My Automated WordPress Site" \
    #     --admin_user=$ADMIN_USER \
    #     --admin_password=$ADMIN_PASSWORD\
    #     --admin_email=$ADMIN_EMAIL \
    #     --skip-email \
    #     --allow-root

    # wp user create --allow-root $WORDPRESS_DB_USER $WORDPRESS_DB_USER_MAIL --user_pass=$WORDPRESS_DB_USER

    # wp theme install --allow-root astra --activate

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
        wp user create --allow-root $WORDPRESS_DB_USER $WORDPRESS_DB_USER_MAIL --user_pass=$WORDPRESS_DB_USER
        
        # echo "Installing and activating Astra theme..."
        # wp theme install --allow-root astra --activate
    else
        echo "WordPress is already installed."
    fi

fi
