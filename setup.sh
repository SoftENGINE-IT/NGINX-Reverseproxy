#!/bin/bash

# Update des Systems und Installation der benötigten Pakete
apt update
apt install curl net-tools sudo nginx certbot python3 python3-full python3-certbot-nginx  -y

# Sicherstellen, dass NGINX Aktiv ist
systemctl enable nginx
systemctl start nginx

echo "Installation abgeschlossen"