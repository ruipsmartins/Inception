#!/bin/sh
set -eu

# ── 1) Ler secrets (passwords) ────────────────────────────────────────────────
DB_USER_PASSWORD="$(cat /run/secrets/db_user_password)"
WP_ADMIN_PASSWORD="$(cat /run/secrets/wp_admin_password)"

# ── 2) Ler variáveis do .env ─────────────────────────────────────────────────
DB_NAME="${DB_NAME:?missing}"
DB_USER="${DB_USER:?missing}"
DB_HOST="${DB_HOST:-mariadb}"
DB_PORT="${DB_PORT:-3306}"

WP_TITLE="${WP_TITLE:-Inception 42}"
WP_ADMIN_USER="${WP_ADMIN_USER:?missing}"     # não pode conter 'admin'
WP_ADMIN_EMAIL="${WP_ADMIN_EMAIL:?missing}"
WP_URL="${WP_URL:?missing}"

# Opcional: segundo user normal (para cumprir a regra dos 2 users)
WP_USER_NAME="${WP_USER_NAME:-}"
WP_USER_EMAIL="${WP_USER_EMAIL:-}"

WEBROOT="/var/www/html"

# ── 3) Esperar pelo MariaDB ficar disponível ─────────────────────────────────
echo "⏳ A aguardar pelo MariaDB em ${DB_HOST}:${DB_PORT}..."
i=0
until mariadb -h "${DB_HOST}" -P "${DB_PORT}" -u "${DB_USER}" -p"${DB_USER_PASSWORD}" -e "SELECT 1" >/dev/null 2>&1; do
  i=$((i+1))
  if [ "$i" -gt 60 ]; then
    echo "❌ MariaDB não ficou disponível a tempo."
    exit 1
  fi
  sleep 1
done
echo "✅ MariaDB disponível."

# ── 4) Preparar permissões do webroot ────────────────────────────────────────
mkdir -p "${WEBROOT}"
chown -R www-data:www-data /var/www
cd "${WEBROOT}"

# ── 5) Instalar WordPress (se ainda não existir) ─────────────────────────────
if [ ! -f "wp-config.php" ]; then
  echo "📦 A descarregar o core do WordPress..."
  wp core download --allow-root

  echo "📝 A criar wp-config.php..."
  wp config create \
    --dbname="${DB_NAME}" \
    --dbuser="${DB_USER}" \
    --dbpass="${DB_USER_PASSWORD}" \
    --dbhost="${DB_HOST}:${DB_PORT}" \
    --dbprefix="wp_" \
    --skip-check \
    --allow-root

  echo "🚀 A instalar o WordPress..."
  wp core install \
    --url="${WP_URL}" \
    --title="${WP_TITLE}" \
    --admin_user="${WP_ADMIN_USER}" \
    --admin_password="${WP_ADMIN_PASSWORD}" \
    --admin_email="${WP_ADMIN_EMAIL}" \
    --skip-email \
    --allow-root

  # Criar um segundo utilizador (não-admin), se nos tiveres dado nome/email
  if [ -n "${WP_USER_NAME}" ] && [ -n "${WP_USER_EMAIL}" ]; then
    # gera uma password aleatória sem a mostrar nos logs
    RAND_PASS="$(tr -dc 'A-Za-z0-9@#%+=' </dev/urandom | head -c 16 || true)"
    wp user create "${WP_USER_NAME}" "${WP_USER_EMAIL}" \
      --role=author \
      --user_pass="${RAND_PASS}" \
      --porcelain \
      --allow-root >/dev/null 2>&1 || true
    echo "👤 Utilizador extra '${WP_USER_NAME}' criado (password guardada internamente)."
  fi
fi

# ── 6) Arrancar o php-fpm em foreground (boa prática PID 1) ──────────────────
PHP_DIR="$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')"
echo "▶️  A iniciar /usr/sbin/php-fpm${PHP_DIR} (foreground)..."
exec "/usr/sbin/php-fpm${PHP_DIR}" -F