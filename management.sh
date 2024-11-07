#!/bin/bash

# Auswahlmenü anzeigen
echo ""
echo "Was möchten Sie tun?"
echo "-------------------------------------------------------"
echo ""
echo "1: Installation der Umgebung auf einem Debian12 System"
echo "2: Erstellung eines neuen ProxyHosts"
echo ""
read -p "Wählen Sie eine Option (1 oder 2): " option

# Auswahl überprüfen und entsprechende Aktion ausführen
if [ "$option" -eq 1 ]; then
    # Option 1: Installation der Umgebung auf einem Debian12 System
    echo "Starte die Installation der Umgebung auf einem Debian12 System..."
    ./setup.sh
    echo "Installation abgeschlossen."

elif [ "$option" -eq 2 ]; then
    # Option 2: Erstellung eines neuen ProxyHosts
    
    # Benutzereingaben abfragen
    read -p "Geben Sie den FQDN an (z.B. server.example.com): " fqdn
    read -p "Geben Sie die IP des internen Servers an: " internal_ip
    read -p "Geben Sie den Port der internen Anwendung an: " internal_port
    read -p "Geben Sie den externen Port an (z.B. 443): " external_port

    # Extrahiere die Subdomain aus dem FQDN
    subdomain=$(echo "$fqdn" | cut -d '.' -f1)

    # Dateiname für die Konfigurationsdatei
    conf_file="/etc/nginx/conf.d/${subdomain}.conf"

    # Erstelle die Konfigurationsdatei
    cat <<EOF > "$conf_file"
server {
    listen 80;
    listen [::]:80;

    server_name $fqdn;

    location / {
        proxy_pass http://$internal_ip:$internal_port;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

    echo "Konfigurationsdatei $conf_file wurde erfolgreich erstellt."

    # NGINX neu laden
    nginx -s reload
    echo "Die NGINX Konfiguration wurde neu geladen."

    # Zertifikat erstellen
    certbot --nginx -d "$fqdn"
    echo "Zertifikat wurde erfolgreich erstellt."

    # Vorherige Konfiguration entfernen und aktualisierte Konfiguration schreiben
    rm "$conf_file"

    cat <<EOF > "$conf_file"
server {

    server_name $fqdn;

    location / {
        proxy_pass http://$internal_ip:$internal_port/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    listen [::]:$external_port ssl ipv6only=on; # managed by Certbot
    listen $external_port ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/$fqdn/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/$fqdn/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
}

server {
    if (\$host = $fqdn) {
        return 301 https://\$host:$external_port\$request_uri;
    } # managed by Certbot

    listen 80;
    listen [::]:80;

    server_name $fqdn;
    return 404; # managed by Certbot
}
EOF

    # NGINX neu laden
    nginx -s reload
    echo "Die NGINX Konfiguration wurde neu geladen."

else
    echo "Ungültige Auswahl. Bitte wählen Sie entweder 1 oder 2."
fi
