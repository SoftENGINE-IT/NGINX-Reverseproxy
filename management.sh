#!/bin/bash

# Prüfen, ob genau 6 Argumente übergeben wurden
# Falls ja, werden diese für Option 2 (ProxyHost erstellen) verwendet.
if [ "$#" -eq 6 ]; then
    # CLI-Variablen zuweisen
    fqdn="$1"                # 1. Param: Domain (z.B. subdomain.example.com)
    internal_ip="$2"         # 2. Param: Interne IP (z.B. 192.168.0.123)
    foreward_scheme="$3"     # 3. Param: http oder https
    enable_websockets="$4"   # 4. Param: y oder n
    internal_port="$5"       # 5. Param: Interner Port (z.B. 8080)
    external_port="$6"       # 6. Param: Externer Port (z.B. 443)

    # Wir springen direkt in die Erstellung eines ProxyHosts (Option 2)
    option=2

else
    # Kein direkter CLI-Aufruf mit 6 Parametern => Menü anzeigen
    echo "Was möchten Sie tun?"
    echo "-------------------------------------------------------"
    echo ""
    echo "1: Installation der Umgebung auf einem Debian12 System"
    echo "2: Erstellung eines neuen ProxyHosts"
    echo ""
    read -p "Wählen Sie eine Option (1 oder 2): " option
fi

# -------------------------------
# Option 1: Installation
# -------------------------------
if [ "$option" -eq 1 ]; then
    echo "Starte die Installation der Umgebung auf einem Debian12 System..."
    ./setup.sh
    echo "Installation abgeschlossen."
    exit 0
fi

# -------------------------------
# Option 2: ProxyHost erstellen
# -------------------------------
if [ "$option" -eq 2 ]; then
    
    # Falls keine 6 CLI-Argumente übergeben wurden,
    # müssen wir (interaktiv) alle Variablen erfragen.
    if [ "$#" -ne 6 ]; then
        read -p "Geben Sie den FQDN an (z.B. server.example.com): " fqdn
        read -p "Geben Sie die IP des internen Servers an: " internal_ip
        read -p "Geben Sie das forward scheme an (http oder https): " foreward_scheme
        read -p "Sollen Websockets aktiviert werden? (y/n): " enable_websockets
        read -p "Geben Sie den Port des internen Servers an (z.B. 8080): " internal_port
        read -p "Geben Sie den externen Port an (z.B. 443): " external_port
    fi

    # Dateiname für die Konfigurationsdatei
    conf_file="/etc/nginx/conf.d/$fqdn.conf"

    # Prüfen, ob die Konfigurationsdatei bereits existiert
    if [ -f "$conf_file" ]; then
        echo "Die Konfigurationsdatei $conf_file existiert bereits."
        read -p "Möchten Sie den Proxy-Host neu anlegen und die Datei überschreiben (o) oder einen neuen Service hinzufügen (h)? (o/h): " choice

        if [ "$choice" == "o" ]; then
            # Datei überschreiben
            rm "$conf_file"
            echo "Bestehende Datei wird überschrieben."

        elif [ "$choice" == "h" ]; then
            # Neue Werte für zusätzlichen Service abfragen
            echo "Bitte geben Sie die Daten für den neuen Service ein."
            read -p "Geben Sie das foreward scheme an (http oder https): " new_foreward_scheme
            read -p "Geben Sie die IP des neuen internen Servers an: " new_internal_ip
            read -p "Geben Sie den Port des neuen internen Servers an: " new_internal_port
            read -p "Geben Sie den externen Port für den neuen Service an: " new_external_port

            # Websocket-Header je nach Einstellung
            if [ "$enable_websockets" == "y" ]; then
                websocket_headers="proxy_set_header Upgrade            \$http_upgrade;
        proxy_set_header Connection         \$http_connection;
        proxy_http_version 1.1;"
            else
                websocket_headers="# proxy_set_header Upgrade            \$http_upgrade;
        # proxy_set_header Connection         \$http_connection;
        # proxy_http_version 1.1;"
            fi
            
            # Prüfen, ob in diesem „zusätzlichen Service“ der externe Port 443 ist
            # => dann soll der zweite Server-Block im Listen-Port auf 80 wechseln
            listen_redirect_port="$new_external_port"
            if [ "$new_external_port" = "443" ]; then
                listen_redirect_port="80"
            fi

            # Konfiguration für den neuen Service an bestehende Datei anhängen
            cat <<EOF >> "$conf_file"
server {

    server_name $fqdn;

    client_max_body_size 100M;

    location / {
        proxy_pass $new_foreward_scheme://$new_internal_ip:$new_internal_port/;

        # Default Header
        proxy_set_header Host               \$host;
        proxy_set_header X-Forwarded-Scheme \$scheme;
        proxy_set_header X-Forwarded-Proto  \$scheme;
        proxy_set_header X-Forwarded-For    \$remote_addr;
        proxy_set_header X-Real-IP          \$remote_addr;

        # Websocket Header 
        $websocket_headers
    }

    listen $new_external_port ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/$fqdn/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/$fqdn/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
}

server {
    listen $listen_redirect_port;
    server_name $fqdn;

    # Umleitung zu HTTPS auf Port $new_external_port
    return 301 https://\$host:$new_external_port\$request_uri;
}
EOF
            echo "Neuer Service wurde zur bestehenden Konfigurationsdatei hinzugefügt."
            nginx -s reload
            echo "Die NGINX Konfiguration wurde neu geladen."
            exit 0

        else
            echo "Ungültige Auswahl. Das Skript wird beendet."
            exit 1
        fi
    fi

    # Ab hier wird eine (ggf. neue) Konfiguration erstellt
    # Websocket-Header anpassen
    if [ "$enable_websockets" == "y" ]; then
        websocket_headers="proxy_set_header Upgrade            \$http_upgrade;
        proxy_set_header Connection         \$http_connection;
        proxy_http_version 1.1;"
    else
        websocket_headers="# proxy_set_header Upgrade            \$http_upgrade;
        # proxy_set_header Connection         \$http_connection;
        # proxy_http_version 1.1;"
    fi

    # 1. Schritt: Plain-HTTP-Block (Port 80) erzeugen
    cat <<EOF > "$conf_file"
server {
    listen 80;

    server_name $fqdn;

    client_max_body_size 100M;

    location / {
        proxy_pass $foreward_scheme://$internal_ip:$internal_port/;

        # Default Header
        proxy_set_header Host               \$host;
        proxy_set_header X-Forwarded-Scheme \$scheme;
        proxy_set_header X-Forwarded-Proto  \$scheme;
        proxy_set_header X-Forwarded-For    \$remote_addr;
        proxy_set_header X-Real-IP          \$remote_addr;

        # Websocket Header 
        $websocket_headers
    }
}
EOF

    echo "Konfigurationsdatei $conf_file wurde (vorläufig) erstellt."
    # NGINX neu laden
    nginx -s reload
    echo "Die NGINX Konfiguration wurde neu geladen."

    # Zertifikat anfordern
    certbot --nginx -d "$fqdn"
    echo "Zertifikat wurde erfolgreich erstellt (falls erfolgreich)."

    # 2. Schritt: vorhandene Konfiguration durch SSL-Version ersetzen
    rm "$conf_file"

    # Hier prüfen wir, ob der externe Port == 443 ist.
    # Wenn ja, soll der Redirect-Port auf 80 laufen.
    listen_redirect_port="$external_port"
    if [ "$external_port" = "443" ]; then
        listen_redirect_port="80"
    fi

    cat <<EOF > "$conf_file"
server {

    server_name $fqdn;

    client_max_body_size 100M;

    location / {
        proxy_pass $foreward_scheme://$internal_ip:$internal_port/;

        # Default Header
        proxy_set_header Host               \$host;
        proxy_set_header X-Forwarded-Scheme \$scheme;
        proxy_set_header X-Forwarded-Proto  \$scheme;
        proxy_set_header X-Forwarded-For    \$remote_addr;
        proxy_set_header X-Real-IP          \$remote_addr;

        # Websocket Header 
        $websocket_headers
    }

    listen $external_port ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/$fqdn/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/$fqdn/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
}

server {
    listen $listen_redirect_port;
    server_name $fqdn;

    # Umleitung zu HTTPS auf demselben Port
    return 301 https://\$host:$external_port\$request_uri;
}
EOF

    # NGINX neu laden
    nginx -s reload
    echo "Die NGINX Konfiguration wurde neu geladen."
    exit 0
fi

# Wenn weder Option 1 noch Option 2 zutrifft (z.B. falsche Eingabe)
echo "Ungültige Auswahl. Bitte wählen Sie entweder 1 oder 2 (oder übergeben Sie 6 Parameter direkt)."
exit 1
