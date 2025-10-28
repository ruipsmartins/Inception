#!/bin/sh

# Ler passwords dos secrets (com retry para evitar falhas transitórias)
read_secret() {
  path="$1"
  tries=0
  while [ ! -f "$path" ] && [ "$tries" -lt 30 ]; do
    tries=$((tries+1))
    sleep 1
  done
  [ -f "$path" ] && cat "$path" || echo ""
}

DB_PASS="$(read_secret /run/secrets/db_user_password)"
ADMIN_PASS="$(read_secret /run/secrets/wp_admin_password)"
WP_USER_PASS="$(read_secret /run/secrets/wp_user_password)"

# Defaults seguros caso .env não defina
: "${DB_NAME:=wordpress}"
: "${DB_USER:=wpuser}"
: "${DB_HOST:=mariadb}"
: "${DB_PORT:=3306}"

cd /var/www/html

# Instalar WordPress (idempotente) apenas se não existir wp-config.php
if [ ! -f wp-config.php ]; then
  echo "A instalar WordPress..."

  # Esperar pela base de dados ficar acessível
  tries=0
  until mariadb -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" -e "SELECT 1" >/dev/null 2>&1; do
    tries=$((tries+1))
    if [ "$tries" -ge 30 ]; then
      echo "Aviso: DB ainda indisponível, a prosseguir mesmo assim..."
      break
    fi
    sleep 1
  done

  # Fazer download apenas se os ficheiros core não estiverem presentes
  set +e
  if [ ! -f wp-includes/version.php ]; then
    wp core download --allow-root --force || true
  fi

  # Criar wp-config.php
  wp config create \
    --dbname="$DB_NAME" \
    --dbuser="$DB_USER" \
    --dbpass="$DB_PASS" \
    --dbhost="$DB_HOST:$DB_PORT" \
    --allow-root || true

  # Executar instalação (apenas se variáveis mínimas estiverem definidas)
  if [ -n "$WP_URL" ] && [ -n "$WP_TITLE" ] && [ -n "$WP_ADMIN_USER" ] && [ -n "$ADMIN_PASS" ] && [ -n "$WP_ADMIN_EMAIL" ]; then
    wp core install \
      --url="$WP_URL" \
      --title="$WP_TITLE" \
      --admin_user="$WP_ADMIN_USER" \
      --admin_password="$ADMIN_PASS" \
      --admin_email="$WP_ADMIN_EMAIL" \
      --skip-email \
      --allow-root || true
  else
    echo "Aviso: Variáveis WP_* em falta, a saltar 'wp core install'."
  fi

  # Criar/atualizar utilizador adicional
  wp user get "$WP_USER_NAME" --field=ID --allow-root >/dev/null 2>&1 || \
    wp user create "$WP_USER_NAME" "$WP_USER_EMAIL" --role=author --allow-root
  wp user update "$WP_USER_NAME" --user_pass="$WP_USER_PASS" --allow-root || true
  set -e
fi

# Iniciar PHP-FPM
PHP_VER="$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')"
echo "A iniciar php-fpm${PHP_VER}..."
exec "/usr/sbin/php-fpm${PHP_VER}" -F
