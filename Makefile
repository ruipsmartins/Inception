NAME = inception
COMPOSE = docker compose -f srcs/docker-compose.yml

all: up

up:
	mkdir -p /home/ruidos-s/data/db
	mkdir -p /home/ruidos-s/data/wp
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
	sudo rm -rf /home/ruidos-s/data/

.PHONY: all up down re ps logs clean fclean