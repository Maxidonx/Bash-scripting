#!/bin/bash

# Variables
APP_NAME="my-web-app"
APP_REPO="https://github.com/username/my-web-app.git"
APP_DIR="/var/www/$APP_NAME"
DOCKER_IMAGE="$APP_NAME:latest"
DOMAIN="example.com"
PORT=${PORT:-8000}
USE_DB=true  # Set to false to skip database configuration
USE_REMOTE_DB=false  # Set to true for remote DB
DB_HOST=${DB_HOST:-"localhost"}
DB_PORT=${DB_PORT:-3306}
DB_NAME=${DB_NAME:-"my_database"}
DB_USER=${DB_USER:-"my_user"}
DB_PASSWORD=${DB_PASSWORD:-"secure_password"}
ADMIN_EMAIL=${ADMIN_EMAIL:-"admin@example.com"}

# Update and Install Dependencies
echo "Updating and installing required packages..."
apt update && apt upgrade -y || { echo "Package update failed. Exiting."; exit 1; }
apt install -y nginx git docker.io docker-compose certbot python3-certbot-nginx mysql-client || { echo "Package installation failed. Exiting."; exit 1; }

# Configure Firewall
echo "Configuring firewall..."
ufw allow ssh || { echo "Failed to configure SSH firewall rule."; exit 1; }
ufw allow 'Nginx Full' || { echo "Failed to configure Nginx firewall rule."; exit 1; }
ufw --force enable || { echo "Failed to enable UFW. Exiting."; exit 1; }

# Clone Application Repository
echo "Cloning application repository..."
if [ ! -d "$APP_DIR" ]; then
    git clone $APP_REPO $APP_DIR || { echo "Failed to clone repository. Exiting."; exit 1; }
else
    echo "Application directory already exists. Pulling latest changes..."
    cd $APP_DIR && git pull origin main || { echo "Failed to update repository. Exiting."; exit 1; }
fi

# Generate Docker Compose File
echo "Generating Docker Compose file..."
cat << EOF > $APP_DIR/docker-compose.yml
version: '3.8'

services:
  app:
    build: .
    container_name: $APP_NAME
    ports:
      - "$PORT:8000"
    environment:
      - PORT=$PORT
      - DB_HOST=$DB_HOST
      - DB_PORT=$DB_PORT
      - DB_NAME=$DB_NAME
      - DB_USER=$DB_USER
      - DB_PASSWORD=$DB_PASSWORD
    volumes:
      - .:/app
    depends_on:
      - db

  db:
    image: mysql:latest
    container_name: ${APP_NAME}_db
    environment:
      MYSQL_ROOT_PASSWORD: root_password
      MYSQL_DATABASE: $DB_NAME
      MYSQL_USER: $DB_USER
      MYSQL_PASSWORD: $DB_PASSWORD
    ports:
      - "3306:3306"
    volumes:
      - db_data:/var/lib/mysql

volumes:
  db_data:
EOF

# Build and Run Docker Containers
echo "Building and running Docker containers..."
cd $APP_DIR
docker-compose up -d || { echo "Docker Compose up failed. Exiting."; exit 1; }

# Configure Nginx with SSL
echo "Configuring Nginx and SSL..."
cat << EOF > /etc/nginx/sites-available/$DOMAIN
server {
    listen 80;
    server_name $DOMAIN;

    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name $DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    location / {
        proxy_pass http://localhost:$PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Additional security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-XSS-Protection "1; mode=block";
}
EOF

ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
nginx -t || { echo "Nginx configuration test failed. Exiting."; exit 1; }
systemctl restart nginx || { echo "Failed to restart Nginx. Exiting."; exit 1; }

# Setup SSL
echo "Setting up SSL..."
certbot --nginx -n -m $ADMIN_EMAIL -d $DOMAIN --agree-tos --no-eff-email || { echo "SSL setup failed."; exit 1; }

# Database Configuration (Conditional)
if $USE_DB; then
    if $USE_REMOTE_DB; then
        echo "Using remote database..."
        echo "Testing connection to remote database..."
        if ! mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASSWORD -e "USE $DB_NAME;"; then
            echo "Failed to connect to remote database. Exiting."
            exit 1
        fi
    else
        echo "Using local MySQL database..."
        echo "Setting up local database..."
        docker exec ${APP_NAME}_db mysql -uroot -proot_password -e "
        CREATE DATABASE IF NOT EXISTS $DB_NAME;
        CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD';
        GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'%';
        FLUSH PRIVILEGES;"
    fi
else
    echo "Skipping database configuration as USE_DB is set to false."
fi

# Clean Up
echo "Cleaning up unused Docker resources..."
docker container prune -f
docker image prune -f

echo "Deployment complete! Visit https://$DOMAIN"
