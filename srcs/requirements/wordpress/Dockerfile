# penúltima versão estável do debian
FROM debian:12

# Evita prompts do apt
ENV DEBIAN_FRONTEND=noninteractive

# PHP-FPM + extensões necessárias ao WordPress + cliente mariadb + utilitários
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      php-fpm php-mysql php-cli php-curl php-xml php-mbstring php-zip php-gd \
      mariadb-client curl ca-certificates tar less \
 && rm -rf /var/lib/apt/lists/*

# Ajuste do PHP-FPM para ouvir em todas as interfaces (0.0.0.0)
# Por defeito, o PHP-FPM ouve só em localhost (127.0.0.1)
RUN sed -ri 's|^listen = .*|listen = 0.0.0.0:9000|' /etc/php/*/fpm/pool.d/www.conf

# Instalar wp-cli (ferramenta de linha de comandos para gerir WordPress)
RUN curl -fsSL -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
 && chmod +x /usr/local/bin/wp \
 && wp --allow-root --path=/tmp --version

# Pasta do site + permissões
RUN mkdir -p /var/www/html \
 && chown -R www-data:www-data /var/www

# Copiar o entrypoint e torná-lo executável
COPY ./tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Definir a pasta de trabalho
WORKDIR /var/www/html
EXPOSE 9000

# O entrypoint vai tratar da inicialização do WordPress e do arranque do PHP-FPM
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
