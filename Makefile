NAME = inception
COMPOSE = docker compose -f srcs/docker-compose.yml

all: up

up:
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

re: down up

ps:
	@$(COMPOSE) ps

logs:
	@$(COMPOSE) logs -f

clean: down
	@docker volume rm -f $$(docker volume ls -q | grep $(NAME)_ || true)
	@docker network rm -f $$(docker network ls -q | grep $(NAME)_ || true)

fclean: clean
	@docker system prune -af --volumes

.PHONY: all up down re ps logs clean fclean