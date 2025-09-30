# penúltima versão estável do debian
FROM debian:12

ENV DEBIAN_FRONTEND=noninteractive

# PHP-FPM + extensões necessárias ao WordPress + cliente mariadb + utilitários
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      php-fpm php-mysql php-cli php-curl php-xml php-mbstring php-zip php-gd \
      mariadb-client curl ca-certificates tar less \
 && rm -rf /var/lib/apt/lists/*

# Ajustar o PHP-FPM para escutar em TCP 0.0.0.0:9000 (em vez de unix socket),
# para o Nginx (noutro container) conseguir ligar via rede docker.
# Edita o www.conf, qualquer que seja a versão do PHP (7.x/8.x)
RUN sed -ri 's|^listen = .*|listen = 0.0.0.0:9000|' /etc/php/*/fpm/pool.d/www.conf

# Instalar wp-cli (ferramenta de linha de comandos para gerir WordPress)
RUN curl -fsSL -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
 && chmod +x /usr/local/bin/wp \
 && wp --allow-root --path=/tmp --version

# Pasta do site + permissões
RUN mkdir -p /var/www/html \
 && chown -R www-data:www-data /var/www

# Copiamos o entrypoint (vamos criá-lo a seguir)
COPY ./tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /var/www/html
EXPOSE 9000

# O entrypoint vai tratar da instalação/configuração do WP e depois executar o php-fpm em foreground
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
