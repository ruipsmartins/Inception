NAME = inception
COMPOSE = docker compose -f srcs/docker-compose.yml
HOST_DATA_DIR = /home/ruidos-s/data
ENV_FILE = srcs/.env
SECRETS_DIR = srcs/secrets

all: up

init:
	@mkdir -p $(HOST_DATA_DIR)/mariadb $(HOST_DATA_DIR)/wordpress
	@mkdir -p $(SECRETS_DIR)
	@[ -f $(SECRETS_DIR)/db_root_password.txt ] || echo 'change-me-root' > $(SECRETS_DIR)/db_root_password.txt
	@[ -f $(SECRETS_DIR)/db_user_password.txt ] || echo 'change-me-wpdb' > $(SECRETS_DIR)/db_user_password.txt
	@[ -f $(SECRETS_DIR)/wp_admin_password.txt ] || echo 'change-me-admin' > $(SECRETS_DIR)/wp_admin_password.txt
	@[ -f $(SECRETS_DIR)/wp_user_password.txt ] || echo 'change-me-user' > $(SECRETS_DIR)/wp_user_password.txt
	@[ -f $(ENV_FILE) ] || echo "DB_NAME=wordpress\nDB_USER=wpuser\nDB_HOST=mariadb\nDB_PORT=3306\n\nWP_URL=https://localhost\nWP_TITLE=Inception\nWP_ADMIN_USER=admin\nWP_ADMIN_EMAIL=admin@example.local\nWP_USER_NAME=author\nWP_USER_EMAIL=author@example.local\n\nDOMAIN=localhost\n" > $(ENV_FILE)

up: init
	@$(COMPOSE) up -d --build

down:
	@$(COMPOSE) down

mariaup: init
	@$(COMPOSE) up -d --build mariadb

marialogs:
	@$(COMPOSE) logs -f mariadb

marialogin:
	docker exec -it mariadb mariadb -u wpuser -p

wpressup: init
	@$(COMPOSE) up -d --build wordpress

wpresslogs:
	@$(COMPOSE) logs -f wordpress

wpressexec:
	docker exec -it --user root wordpress bash

re: down up

ps:
	@$(COMPOSE) ps

logs:
	@$(COMPOSE) logs -f

fclean: down
	@docker system prune -af --volumes
	sudo rm -rf $(HOST_DATA_DIR)

volumes:
	@docker volume ls

inspect-db:
	@docker volume inspect db_data || true

inspect-wp:
	@docker volume inspect wp_data || true

.PHONY: all init up down re ps logs clean fclean volumes inspect-db inspect-wp