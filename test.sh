#!/bin/bash

# Check if a domain was provided
if [ -z "$1" ]; then
    echo "Usage: $0 domain_name"
    exit 1
fi

DOMAIN=$1
NGINX_CONFIG="/etc/nginx/sites-available/$DOMAIN"
NGINX_ENABLED="/etc/nginx/sites-enabled/$DOMAIN"
CERTBOT_EMAIL="darkw4v3@gmail.com" # Replace with your email

# Step 1: Create a new Nginx server block for the domain
cat > $NGINX_CONFIG <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN www.$DOMAIN;

    location / {
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'Upgrade';
        proxy_set_header Host \$host;

        proxy_connect_timeout 10; 
        proxy_send_timeout 90; 
        proxy_read_timeout 90; 
        proxy_buffer_size 128k;
        proxy_buffers 4 256k;
        proxy_busy_buffers_size 256k;
        proxy_temp_file_write_size 256k;

        proxy_pass http://127.0.0.1:8000;  # Replace with your app's backend
    }

    # Block Googlebot or any other specific user agent
    if (\$http_user_agent ~ (Googlebot)) {
        return 403;
    }
}
EOF

# Step 2: Enable the configuration by creating a symlink
ln -s $NGINX_CONFIG $NGINX_ENABLED

# Step 3: Test and reload Nginx configuration
nginx -t
if [ $? -eq 0 ]; then
    systemctl reload nginx
else
    echo "Nginx configuration failed. Please check the syntax."
    exit 1
fi

# Step 4: Use Certbot to obtain an SSL certificate for the domain
certbot --nginx --non-interactive --agree-tos --email $CERTBOT_EMAIL -d $DOMAIN -d www.$DOMAIN

# Step 5: Reload Nginx to apply the SSL configuration
systemctl reload nginx

echo "Domain $DOMAIN has been configured and SSL certificate generated."
