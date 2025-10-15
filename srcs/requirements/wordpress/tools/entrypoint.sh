#!/bin/sh
set -e

# Ler passwords dos secrets
DB_PASS="$(cat /run/secrets/db_user_password)"
ADMIN_PASS="$(cat /run/secrets/wp_admin_password)"

cd /var/www/html

# Instalar WordPress se ainda não existir
if [ ! -f wp-config.php ]; then
  echo "A instalar WordPress..."

  wp core download --allow-root
  wp config create \
    --dbname="$DB_NAME" \
    --dbuser="$DB_USER" \
    --dbpass="$DB_PASS" \
    --dbhost="$DB_HOST:$DB_PORT" \
    --allow-root

  wp core install \
    --url="$WP_URL" \
    --title="$WP_TITLE" \
    --admin_user="$WP_ADMIN_USER" \
    --admin_password="$ADMIN_PASS" \
    --admin_email="$WP_ADMIN_EMAIL" \
    --skip-email \
    --allow-root

  wp user create "$WP_USER_NAME" "$WP_USER_EMAIL" --role=author --allow-root
fi

# Iniciar PHP-FPM
PHP_VER="$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')"
echo "A iniciar php-fpm${PHP_VER}..."
exec "/usr/sbin/php-fpm${PHP_VER}" -F
