# NGINX Proxy Host Management Script

Dieses Bash-Skript vereinfacht die Verwaltung von Proxy-Hosts auf einem Debian 12 System. Es ermöglicht die Installation einer Umgebung sowie das Hinzufügen und Konfigurieren neuer Proxy-Hosts auf NGINX, einschließlich der Möglichkeit zur Aktivierung von Websocket-Headern.

## Funktionen

- **Installation der Umgebung auf einem Debian 12-System**
- **Erstellung eines neuen Proxy-Hosts** mit benutzerdefinierten Einstellungen
- **Option zur Aktivierung von Websockets**: Möglichkeit, Websocket-Header automatisch zu aktivieren oder auszukommentieren
- **SSL-Zertifikate** durch Certbot Integration für automatische Zertifikaterstellung und Updates

## Voraussetzungen

- Debian 12
- Root- oder sudo-Zugriff
- Portforewarding zum Zielsystem mit dem Ports 80 und 443 (und ggf. andere gebrauchte)

## Setup/Vorbereitung

1. Klone das Repository:
   ```bash
   git clone https://github.com/SoftENGINE-IT/NGINX-Reverseproxy.git
   cd NGINX-Reverseproxy
2. Ausführbar machen der Skripte:
   ```bash
    chmod +x management.sh && chmod +x setup.sh
3. Ausführen des management Skriptes:
   ```bash
   ./management.sh

## Funktion

Grundsätzlich installiert das Skipt automatisch NGINX und Certbot mit allen Abhängigkeiten für NGINX zur Verwendung als Reverseproxy mit lokal gemanageden Zertifikaten, die auch automatisch erneuert werden.

Für die Zertifikatsausstellung wird der Port 80 als direkte Portweiterleitung zum NGINX system benötigt.
Zusätzlich wird ebenso eine direkte Portweiterleitung für jeden weiteren, extern verwendeten Port benötigt. Im Standrard nur 443.

Die Konfigurationen werden aufbewahrt unter **/etc/nginx/conf.d/** und die Zertifikate unter **/etc/letsencrypt/live/**.

Beispiel einer Kinfiguration mit aktivierten Websockets:
```conf
server {

    server_name meine-domain.example.com;

    location / {
        proxy_pass https://192.168.1.10:8080/;

        # Default Header
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Scheme $scheme;
        proxy_set_header X-Forwarded-Proto  $scheme;
        proxy_set_header X-Forwarded-For    $remote_addr;
        proxy_set_header X-Real-IP          $remote_addr;

        # Websocket Header
        proxy_set_header Upgrade            $http_upgrade;
        proxy_set_header Connection         $http_connection;
        proxy_http_version 1.1;
    }

    listen [::]:443 ssl ipv6only=on; # managed by Certbot
    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/meine-domain.example.com/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/meine-domain.example.com/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
}

server {
    listen 80;
    listen [::]:80;
    server_name meine-domain.example.com;

    # Umleitung zu HTTPS auf demselben Port
    return 301 https://$host:443$request_uri;
}
```

Bei Fehlern oder Problemen kann durch logs oder das in NGINX eingebaute Tool zur Validierung der Konfigurationsdateien überprüft werden, wo der Fehler liegt.

Live Logs für zusätzliche Terminal-Session:
```bash
tail -f /var/log/nginx/error.log
```

Eingebautes Validierungstool:
```bash
nginx -t
```
