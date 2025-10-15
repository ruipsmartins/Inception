#!/bin/sh
set -e

CONF="/etc/nginx/conf.d/default.conf"
SSL_DIR="/etc/nginx/ssl"

# domínio a usar (vem do .env)
if [ -z "${DOMAIN:-}" ] && [ -n "${LOGIN:-}" ]; then
  DOMAIN="${LOGIN}.42.fr"
fi
: "${DOMAIN:?Falta DOMAIN no .env (ex.: DOMAIN=ruidos-s.42.fr)}"

mkdir -p "$SSL_DIR" /var/www/html
chown -R www-data:www-data /var/www

CRT="$SSL_DIR/server.crt"
KEY="$SSL_DIR/server.key"

# gerar certificado self-signed se faltar (com SAN = domínio)
if [ ! -f "$CRT" ] || [ ! -f "$KEY" ]; then
  echo "A gerar certificado para ${DOMAIN}..."
  openssl req -x509 -nodes -newkey rsa:4096 -days 365 \
    -keyout "$KEY" -out "$CRT" \
    -subj "/CN=${DOMAIN}" \
    -addext "subjectAltName=DNS:${DOMAIN}"
  chmod 600 "$KEY"
fi

# meter o domínio no server_name (substitui placeholder "_")
sed -ri "s|server_name _;|server_name ${DOMAIN};|" "$CONF"

# validar e arrancar
nginx -t
echo "🚀 Nginx a ouvir em 443 (TLS 1.2/1.3 only) para ${DOMAIN}"
exec nginx -g 'daemon off;'
