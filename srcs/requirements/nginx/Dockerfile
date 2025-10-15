# penúltima versão estável do debian
FROM debian:12

# Evitar prompts do apt
ENV DEBIAN_FRONTEND=noninteractive

# Instalar o Nginx e ferramentas de TLS (openssl) + certificados raiz
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      nginx openssl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Remover o site default (que escuta na porta 80) para garantirmos que só usamos 443
# e preparar pastas de config e de certificados
RUN rm -f /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default || true \
 && mkdir -p /etc/nginx/conf.d /etc/nginx/ssl

# - default.conf: vhost com TLS e proxy para o php-fpm do container "wordpress"
# - entrypoint.sh: gera certificado self-signed se faltar, valida config e arranca o nginx em foreground
COPY ./conf/default.conf /etc/nginx/conf.d/default.conf
COPY ./tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Garantir que o webroot existe (será partilhado com o WordPress via volume)
RUN mkdir -p /var/www/html && chown -R www-data:www-data /var/www

# documenta a porta usada (mapeamento é feito no docker-compose)
EXPOSE 443

# permite shutdown limpo do Nginx em containers
STOPSIGNAL SIGQUIT

# corre em foreground (PID 1) no script de entrypoint (sem tail/sleep)
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
