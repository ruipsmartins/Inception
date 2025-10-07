#!/bin/bash

# Atualizar
sudo apt update && sudo apt -y upgrade

sudo systemctl start ssh
sudo systemctl enable ssh 
sudo systemctl status ssh 

# Instalar Docker Engine + plugin docker compose (v2)
sudo apt -y install ca-certificates curl gnupg lsb-release

# Repo oficial Docker
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
  $(. /etc/os-release; echo "$VERSION_CODENAME") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Usar Docker sem sudo (opcional)
sudo usermod -aG docker "$USER"
# (faz logout/login depois disto)
sudo apt install openssh-server -y

# sempre que alguém pedir ruidos-s.42.fr, responde com o IP 127.0.0.1 (localhost).
echo "127.0.0.1 ruidos-s.42.fr" | sudo tee -a /etc/hosts
