# NGINX Proxy Host Management Script

Dieses Bash-Skript vereinfacht die Verwaltung von Proxy-Hosts auf einem Debian 13 System. Es ermöglicht die Installation einer Umgebung sowie das Hinzufügen und Konfigurieren neuer Proxy-Hosts auf NGINX, einschließlich der Möglichkeit zur Aktivierung von Websocket-Headern.

## Funktionen

- **Installation der Umgebung auf einem Debian 13-System**
- **Erstellung eines neuen Proxy-Hosts** mit interaktivem Skript oder durch direktes anhängen von Parametern
- **Option zur Aktivierung von Websockets**: Möglichkeit, Websocket-Header automatisch zu aktivieren oder auszukommentieren
- **SSL-Zertifikate** durch Certbot Integration für automatische Zertifikaterstellung und Updates
- **Secure Remote Execution Setup** durch erstellung eines neuen Benutzers mit minimalen Rechten

## Voraussetzungen

- Debian 13
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
3. Ausführen des interaktiven management Skriptes:
   ```bash
   ./management.sh

### Ausführung mit Parametern
Die gewünschten Optionen müssen durch Leerzeichen getrennt, genau in der vorgegebenen Reihenfolge eingegeben werden. Diese wäre:

- Domain
- interne IP-Adresse
- Protokoll | http oder https
- Websockest aktivieren? | "y" oder "n"
- interner Anwendungs-Port
- externer Port


Schema:
```bash
./management.sh <Domain> <interne IP> <Protokoll> <Websockets aktivieren? y/n> <interner Port> <externer Port>
```
Konkretes Beispiel:
```bash
./management.sh subdomain.example.com 192.168.0.123 http y 8080 443
```
## Secure Remote Execution

Die sichere Ausfürhrung des management Skripts von einem entfernten Gerät funktioniert so, dass ein im Skript anpassbarer Benutzer erstellt wird. Dieser Benutzer (im Standard autonginx) bekommt durch das hinzufügen des Skripts in die Sudoers Datei mit dem Parameter **NOPASSWD** gefolgt vom Verzeichnis, in dem sich das management.sh Skript befindet, exklusives sudorechte nur mit einem SSH-Key-Pair für diese Datei in genau diesem Pfad.
Beispiel für einen solchen Eintrag:

```bash
autonginx ALL=(ALL) NOPASSWD: /opt/NGINX-Reverseproxy/management.sh
```

Durch das Eintragen des bereitgestellten public-Keys in authorized_keys des neu erstellten Benutzers, ist es dann nur per ssh Aufruf mit genau dem zugehörigen Private-Key möglich, die Datei auszuführen, wenn man diesen Key besitzt, sowie den SSH Port kennt und den genauen Pfad der management.sh Datei hat.

## Funktion

Grundsätzlich installiert das Skipt automatisch NGINX und Certbot mit allen Abhängigkeiten für NGINX zur Verwendung als Reverseproxy mit lokal gemanageden Zertifikaten, die auch automatisch erneuert werden.

Für die Zertifikatsausstellung wird der Port 80 als direkte Portweiterleitung zum NGINX system benötigt.
Zusätzlich wird ebenso eine direkte Portweiterleitung für jeden weiteren, extern verwendeten Port benötigt. Im Standrard nur 443.

Die Konfigurationen werden aufbewahrt unter **/etc/nginx/conf.d/** und die Zertifikate unter **/etc/letsencrypt/live/**.

Beispiel einer Kinfiguration mit aktivierten Websockets:
```conf
server {

    server_name meine-domain.example.com;

    client_max_body_size 100M;

    location / {
        proxy_pass https://192.168.1.10:8080/;

        # Default Header
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Scheme $scheme;
        proxy_set_header X-Forwarded-Proto  $scheme;
        proxy_set_header X-Forwarded-For    $remote_addr;
        proxy_set_header X-Real-IP          $remote_addr;
        # proxy_request_buffering off;
        # proxy_buffering off;  

        # Websocket Header
        proxy_set_header Upgrade            $http_upgrade;
        proxy_set_header Connection         $http_connection;
        proxy_http_version 1.1;
    }

    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/meine-domain.example.com/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/meine-domain.example.com/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
}

server {
    listen 80;
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
