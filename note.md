1- "Local" = Private Docker Network
    Only containers within the same Docker network (cloud1-network) can access MySQL.
    No external access (host, LAN, or internet).
    to test >> sudo apt update && sudo apt install -y mysql-client
               OR  docker exec wordpress ping mysql OR docker exec wordpress nc -zv mysql 3306 if no space to install 

2- one one for the PHP run time; and because we use an image of worpdress the uses php-Fpm, so we have to prove that is in container with wordpress, and to do this: 
    docker exec wordpress ps aux | grep php-fpm 
    # Should show FPM processes
    docker exec wordpress which php-fpm
    # Should return path

3- How It Works in Your Docker Setup
Nginx receives an HTTP request (e.g., /index.php).

Nginx forwards PHP requests to wordpress:9000 (PHP-FPM inside the WordPress container).

PHP-FPM executes WordPress’s PHP files (e.g., wp-admin, themes, plugins).

WordPress interacts with MySQL (if database queries are needed).

PHP-FPM returns processed HTML → Nginx → Client.