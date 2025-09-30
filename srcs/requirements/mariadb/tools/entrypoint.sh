#!/bin/sh
set -e

# passwords vindas dos Docker secrets
DB_ROOT_PASS="$(cat /run/secrets/db_root_password)"
DB_USER_PASS="$(cat /run/secrets/db_user_password)"

# vars do .env
: "${DB_NAME:=wordpress}"
: "${DB_USER:=wpuser}"

DATADIR="/var/lib/mysql"
RUNDIR="/run/mysqld"

# garantir pastas e permissões
mkdir -p "$DATADIR" "$RUNDIR"
chown -R mysql:mysql "$DATADIR" "$RUNDIR"

# primeira inicialização?
if [ ! -d "$DATADIR/mysql" ]; then
  echo "📦 A inicializar dados do MariaDB..."
  mariadb-install-db --user=mysql --datadir="$DATADIR" --skip-test-db > /dev/null

  # arrancar mysqld temporário (sem rede) para correr SQL de bootstrap
  mysqld --user=mysql --datadir="$DATADIR" --skip-networking --socket="$RUNDIR/mysqld.sock" &
  pid="$!"

  # esperar o socket ficar disponível
  while ! mariadb -uroot --socket="$RUNDIR/mysqld.sock" -e "SELECT 1" >/dev/null 2>&1; do
    sleep 1
  done

  # criar DB, utilizador e password do root
  mariadb --socket="$RUNDIR/mysqld.sock" -uroot <<SQL
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_USER_PASS';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_ROOT_PASS';
FLUSH PRIVILEGES;
SQL

  # desligar o temporário
  kill "$pid"; wait "$pid"
fi

echo "▶️  MariaDB a arrancar (foreground)..."
exec mysqld --user=mysql --datadir="$DATADIR" --console
