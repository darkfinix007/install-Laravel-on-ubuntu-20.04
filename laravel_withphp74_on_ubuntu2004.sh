#!/bin/bash

# Update package lists and upgrade
sudo apt update && sudo apt upgrade -y

# Install Apache
sudo apt install apache2 -y

# Install PHP 7.4 and required extensions
sudo apt install software-properties-common ca-certificates lsb-release apt-transport-https
LC_ALL=C.UTF-8 sudo add-apt-repository ppa:ondrej/php
sudo apt update
sudo apt install php7.4 php7.4-cli php7.4-mbstring php7.4-xml php7.4-bcmath php7.4-json php7.4-curl php7.4-zip -y

# Install MySQL Server
sudo apt install mysql-server -y

# Secure MySQL Installation
sudo mysql_secure_installation

# Set MySQL root user password and create database and user for Laravel
MYSQL_ROOT_PASSWORD="your_root_password"
LARAVEL_DB="laravel_db"
LARAVEL_USER="laravel_user"
LARAVEL_PASSWORD="your_laravel_password"

sudo mysql -uroot -p$MYSQL_ROOT_PASSWORD <<MYSQL_SCRIPT
CREATE DATABASE $LARAVEL_DB;
CREATE USER '$LARAVEL_USER'@'localhost' IDENTIFIED BY '$LARAVEL_PASSWORD';
GRANT ALL PRIVILEGES ON $LARAVEL_DB.* TO '$LARAVEL_USER'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Install Composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

# Create a new Laravel project
LARAVEL_PROJECT_NAME="your_project_name"
composer create-project --prefer-dist laravel/laravel $LARAVEL_PROJECT_NAME

# Set Permissions
sudo chown -R $USER:www-data $LARAVEL_PROJECT_NAME
sudo chmod -R 775 $LARAVEL_PROJECT_NAME/storage
sudo chmod -R 775 $LARAVEL_PROJECT_NAME/bootstrap/cache

# Configure Apache for Laravel
sudo bash -c "cat > /etc/apache2/sites-available/$LARAVEL_PROJECT_NAME.conf <<EOF
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/$LARAVEL_PROJECT_NAME/public
    <Directory /var/www/$LARAVEL_PROJECT_NAME>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF"

# Enable the new site and mod_rewrite
sudo a2ensite $LARAVEL_PROJECT_NAME.conf
sudo a2enmod rewrite
sudo systemctl restart apache2

# Move Laravel project to /var/www
sudo mv $LARAVEL_PROJECT_NAME /var/www/$LARAVEL_PROJECT_NAME

# Set up environment variables for Laravel
cp /var/www/$LARAVEL_PROJECT_NAME/.env.example /var/www/$LARAVEL_PROJECT_NAME/.env
sed -i "s/DB_DATABASE=laravel/DB_DATABASE=$LARAVEL_DB/" /var/www/$LARAVEL_PROJECT_NAME/.env
sed -i "s/DB_USERNAME=root/DB_USERNAME=$LARAVEL_USER/" /var/www/$LARAVEL_PROJECT_NAME/.env
sed -i "s/DB_PASSWORD=/DB_PASSWORD=$LARAVEL_PASSWORD/" /var/www/$LARAVEL_PROJECT_NAME/.env

# Generate Laravel application key
cd /var/www/$LARAVEL_PROJECT_NAME
php artisan key:generate

echo "Laravel installation is complete. Please visit your server's IP address or domain to access the Laravel application."
