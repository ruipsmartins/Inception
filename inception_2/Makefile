NAME = inception
COMPOSE = docker compose -f srcs/docker-compose.yml

all: up

up:
	@echo "Criando diretórios necessários..."
	mkdir -p /home/ruidos-s/data/db
	mkdir -p /home/ruidos-s/data/wp
	sudo chown -R $(USER):$(USER) /home/ruidos-s/data/
	chmod -R 755 /home/ruidos-s/data/
	@echo "A iniciar containers..."
	@$(COMPOSE) up -d --build

down:
	@$(COMPOSE) down

mariaup:
	@$(COMPOSE) up -d --build mariadb

marialogs:
	@$(COMPOSE) logs -f mariadb

marialogin:
	docker exec -it mariadb mariadb -u wpuser -p

wpressup:
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

.PHONY: all up down re ps logs clean fclean