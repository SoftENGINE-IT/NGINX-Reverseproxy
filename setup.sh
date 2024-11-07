#!/bin/bash

# Update des Systems und Installation der benötigten Pakete
apt update
apt install -y curl net-tools sudo nginx certbot python3 python3-full python3-python3-certbot-nginx

# Sicherstellen, dass NGINX Aktiv ist
systemctl enable nginx
systemctl start nginx

echo "Installation abgeschlossen"