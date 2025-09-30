# penúltima versão estável do debian
FROM debian:12

# Evita prompts do apt
ENV DEBIAN_FRONTEND=noninteractive

# Instalar MariaDB server (sem extras) e limpar cache do apt
RUN apt-get update \
 && apt-get install -y --no-install-recommends mariadb-server mariadb-client \
 && rm -rf /var/lib/apt/lists/*

# Ajuste para aceitar ligações na rede Docker (0.0.0.0)
# Em alguns builds, o default é 127.0.0.1; garantimos 0.0.0.0.
RUN sed -i 's/^\s*bind-address\s*=.*/bind-address=0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf
# || echo -e "[mysqld]\nbind-address=0.0.0.0" > /etc/mysql/mariadb.conf.d/99-inception.cnf

# Copiar o entrypoint e torná-lo executável
COPY ./tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Porta interna usada pelo MariaDB
EXPOSE 3306

# O entrypoint trata de inicialização e arranque em foreground (sem hacks)
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]