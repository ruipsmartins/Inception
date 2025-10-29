#!/bin/sh
set -eu

CONF="/etc/nginx/conf.d/default.conf"
SSL_DIR="/etc/nginx/ssl"

mkdir -p "$SSL_DIR" /var/www/html
chown -R www-data:www-data /var/www

CRT="$SSL_DIR/server.crt"
KEY="$SSL_DIR/server.key"

# gerar certificado self-signed se faltar
if [ ! -f "$CRT" ] || [ ! -f "$KEY" ]; then
  echo "A gerar certificado para ${DOMAIN}..."
  openssl req -x509 -nodes -newkey rsa:4096 -days 365 \
    -keyout "$KEY" -out "$CRT" \
    -subj "/CN=${DOMAIN}" \
    -addext "subjectAltName=DNS:${DOMAIN}"
  chmod 600 "$KEY"
fi

# meter o domínio no server_name (substitui placeholder "_")
#sed -ri "s|server_name _;|server_name ${DOMAIN};|" "$CONF"

# validar e arrancar
nginx -t
echo "Nginx em 443 (TLS 1.2/1.3 only) para ${DOMAIN}"
exec nginx -g 'daemon off;'
