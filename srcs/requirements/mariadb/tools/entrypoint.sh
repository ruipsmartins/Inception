#!/bin/sh
set -e

# --- Lê segredos (passwords) dos Docker secrets ---
DB_ROOT_PASSWORD="$(cat /run/secrets/db_root_password)"
DB_USER_PASSWORD="$(cat /run/secrets/db_user_password)"

# --- Variáveis vindas do .env ---
DB_NAME="${DB_NAME:-wordpress}"
DB_USER="${DB_USER:-wpuser}"

DATADIR="/var/lib/mysql"
RUNDIR="/run/mysqld"

# Garantir diretórios e permissões
mkdir -p "$DATADIR" "$RUNDIR"
chown -R mysql:mysql "$DATADIR" "$RUNDIR"

# Se o MariaDB ainda não foi inicializado (primeira vez)
if [ ! -d "${DATADIR}/mysql" ]; then
  echo "👉 Inicializar datadir do MariaDB..."
  mariadb-install-db --user=mysql --datadir="$DATADIR" --skip-test-db > /dev/null

  echo "👉 A configurar utilizadores e permissões..."
  # Arranca o mysqld temporariamente sem rede para correr SQL de bootstrap
  mysqld --user=mysql --datadir="$DATADIR" --skip-networking --socket="${RUNDIR}/mysqld.sock" &
  pid="$!"

#  # Esperar o socket aparecer
  i=0
  until mariadb -uroot --socket="${RUNDIR}/mysqld.sock" -e "SELECT 1" >/dev/null 2>&1; do
    i=$((i+1))
    if [ "$i" -gt 60 ]; then
      echo "Erro: mysqld não arrancou a tempo."
      exit 1
    fi
    sleep 1
  done

  # Criar DB, user app e definir password do root
  mariadb --socket="${RUNDIR}/mysqld.sock" -uroot <<-SQL
    CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_USER_PASSWORD}';
    GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';
    ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
    FLUSH PRIVILEGES;
SQL

  # Desligar o mysqld temporário
  kill "$pid"
  wait "$pid"
fi

echo "👉 Arrancar MariaDB (foreground)..."
# Corre em foreground (PID 1) — sem hacks tipo tail/sleep
exec mysqld --user=mysql --datadir="$DATADIR" --console