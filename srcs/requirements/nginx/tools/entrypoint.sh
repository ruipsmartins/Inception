#!/bin/sh
set -eu

CONF="/etc/nginx/conf.d/default.conf"
SSL_DIR="/etc/nginx/ssl"

# 1) Descobrir DOMÍNIO a usar
#   - Prioridade: DOMAIN do .env; se não houver, tenta construir a partir do LOGIN
if [ -z "${DOMAIN:-}" ] && [ -n "${LOGIN:-}" ]; then
  DOMAIN="${LOGIN}.42.fr"
fi
: "${DOMAIN:?Falta a variável DOMAIN. Define-a no .env (ex.: DOMAIN=ruidos-s.42.fr)}"

echo "🔧 domain: ${DOMAIN}"

# 2) Garantir pastas e webroot (partilhado com wordpress)
mkdir -p "${SSL_DIR}" /var/www/html
chown -R www-data:www-data /var/www

# 3) Gerar certificado self-signed se não existir (com SAN = DOMAIN)
CRT="${SSL_DIR}/server.crt"
KEY="${SSL_DIR}/server.key"

if [ ! -f "${CRT}" ] || [ ! -f "${KEY}" ]; then
  echo "🔐 A gerar certificado self-signed para ${DOMAIN}..."
  # OpenSSL 1.1.1 (Debian 11) já suporta -addext
  openssl req -x509 -nodes -newkey rsa:4096 -days 365 \
    -keyout "${KEY}" -out "${CRT}" \
    -subj "/CN=${DOMAIN}" \
    -addext "subjectAltName=DNS:${DOMAIN}"
  chmod 600 "${KEY}"
fi

# 4) Injetar o server_name correto no vhost (substitui o placeholder "_")
if grep -q 'server_name _;' "${CONF}"; then
  sed -ri "s|server_name _;|server_name ${DOMAIN};|g" "${CONF}"
fi

# 5) Validar configuração e arrancar em foreground (PID 1)
nginx -t
echo "🚀 A iniciar Nginx em foreground (TLS 1.2/1.3 only)…"
exec nginx -g 'daemon off;'
