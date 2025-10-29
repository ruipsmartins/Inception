NAME = inception
COMPOSE = docker compose -f srcs/docker-compose.yml

all: up

up:
	@mkdir -p /home/ruidos-s/data/dbdata
	@mkdir -p /home/ruidos-s/data/wpdata
	@$(COMPOSE) up -d --build

down:
	@$(COMPOSE) down

re: down up

ps:
	@$(COMPOSE) ps

logs:
	@$(COMPOSE) logs -f

dbup:
	@$(COMPOSE) up -d --build mariadb
dblogs:
	@$(COMPOSE) logs -f mariadb
dbexec:
	docker exec -it mariadb mariadb -u wpuser -p

wpup:
	@$(COMPOSE) up -d --build wordpress
wplogs:
	@$(COMPOSE) logs -f wordpress
wpexec:
	docker exec -it --user root wordpress bash

nginxup:
	@$(COMPOSE) up -d --build nginx
nginxlogs:
	@$(COMPOSE) logs -f nginx
nginxexec:
	docker exec -it --user root nginx bash

fclean: down
	@docker system prune -af --volumes --
	sudo rm -rf /home/ruidos-s/data/

.PHONY: all up down re ps logs dbup dblogs dbexec wpup wplogs wpexec nginxup nginxlogs nginxexec fclean