#!/bin/sh
set -e

DB_ROOT_PASS="$(cat /run/secrets/db_root_password)"
DB_USER_PASS="$(cat /run/secrets/db_user_password)"

: "${DB_NAME:=wordpress}"
: "${DB_USER:=wpuser}"

DATADIR="/var/lib/mysql"
RUNDIR="/run/mysqld"
mkdir -p "$DATADIR" "$RUNDIR" && chown -R mysql:mysql "$DATADIR" "$RUNDIR"

if [ ! -d "$DATADIR/mysql" ]; then
  mariadb-install-db --user=mysql --datadir="$DATADIR" --skip-test-db >/dev/null
  mysqld --user=mysql --datadir="$DATADIR" --skip-networking --socket="$RUNDIR/mysqld.sock" &
  while ! mariadb -uroot --socket="$RUNDIR/mysqld.sock" -e "SELECT 1" >/dev/null 2>&1; do sleep 1; done
  mariadb --socket="$RUNDIR/mysqld.sock" -uroot <<SQL
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_USER_PASS';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_ROOT_PASS';
FLUSH PRIVILEGES;
SQL
  mysqladmin --socket="$RUNDIR/mysqld.sock" -uroot shutdown
fi

exec mysqld --user=mysql --datadir="$DATADIR" --console
