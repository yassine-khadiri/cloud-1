# # use the official NGINX image
FROM nginx:1.25-bookworm

# Create the SSL directory
RUN mkdir -p /etc/nginx/ssl

# Generate a self-signed SSL certificate
RUN openssl req -newkey rsa:2048 -x509 -nodes -days 365  \
    -keyout /etc/nginx/ssl/private.key \
    -out /etc/nginx/ssl/certificate.crt \
    -subj "/C=MO/ST=KO/L=KO/O=42/CN=42.fr"

# Copy my custom NGINX configuration file
COPY conf/default.conf /etc/nginx/conf.d/default.conf

# Expose port 80 and 443
EXPOSE 80 443

# Start NGINX
CMD [ "nginx", "-g", "daemon off;" ]
