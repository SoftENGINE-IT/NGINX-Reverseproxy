# NRP - NGINX Reverse Proxy Management Tool

Modernes Python CLI-Tool zur Verwaltung von NGINX Reverse Proxy Konfigurationen auf Debian 13 Systemen.

## Features

- **Einfache CLI-Verwaltung**: Intuitive Befehle wie `nrp add`, `nrp remove`, `nrp list`
- **Automatische SSL-Zertifikate**: Integration mit Let's Encrypt (Certbot)
- **Websocket-Unterstützung**: Optional aktivierbare Websocket-Header
- **Interaktive & Nicht-interaktive Modi**: Flexibel nutzbar in Skripten oder manuell
- **Jinja2 Templates**: Flexible und wartbare Konfigurationsvorlagen
- **Remote Execution**: Sichere Verwaltung über SSH mit eingeschränkten Benutzerrechten
- **Validierung**: Automatische Überprüfung von Eingaben (FQDN, IP, Ports)

## Voraussetzungen

- Debian 13 (oder kompatible Linux-Distribution)
- Python 3.8+
- Root- oder sudo-Zugriff
- Portweiterleitung für Ports 80 und 443 (und weitere verwendete Ports)

## Installation

### Methode 1: Von GitHub (empfohlen)

```bash
# Repository klonen
git clone https://github.com/SoftENGINE-IT/NGINX-Reverseproxy.git
cd NGINX-Reverseproxy

# Installieren
pip install .

# Oder für Entwicklung
pip install -e .
```

### Methode 2: Mit pip (wenn veröffentlicht)

```bash
pip install nrp
```

## Erste Schritte

### 1. System Setup

```bash
# Installiert NGINX, Certbot und alle Abhängigkeiten
sudo nrp setup
```

Das Setup führt folgende Schritte durch:
- Installation von NGINX, Certbot und Abhängigkeiten
- Aktivierung und Start von NGINX
- Erstellung eines selbstsignierten Dummy-Zertifikats
- Einrichtung einer Catch-All Konfiguration
- Entfernung der Standard-NGINX-Konfiguration

### 2. Proxy-Host hinzufügen

#### Interaktiv (empfohlen für Einsteiger)

```bash
nrp add
```

Das Tool fragt nach:
- FQDN (z.B. `api.example.com`)
- Interne IP-Adresse (z.B. `192.168.1.10`)
- Interner Port (z.B. `8080`)
- Externer Port (Standard: `443`)
- Protokoll (`http` oder `https`)
- Websockets aktivieren (ja/nein)

#### Mit Parametern (für Automatisierung)

```bash
nrp add example.com \
  --internal-ip 192.168.1.10 \
  --internal-port 8080 \
  --external-port 443 \
  --protocol http \
  --websockets
```

Kurzform:

```bash
nrp add example.com -i 192.168.1.10 -p 8080
```

### 3. Weitere Befehle

```bash
# Alle Proxy-Hosts auflisten
nrp list

# Proxy-Host entfernen
nrp remove example.com

# Status anzeigen
nrp status
nrp status --detailed

# Hilfe anzeigen
nrp --help
nrp add --help
```

## CLI-Referenz

### `nrp setup`

Installiert die Umgebung auf einem Debian 13 System.

```bash
sudo nrp setup [--skip-packages]
```

**Optionen:**
- `--skip-packages`: Überspringt die Paketinstallation

### `nrp add`

Erstellt einen neuen Proxy-Host.

```bash
nrp add [FQDN] [OPTIONS]
```

**Optionen:**
- `-i, --internal-ip TEXT`: Interne IP-Adresse
- `-p, --internal-port INTEGER`: Interner Port
- `-e, --external-port INTEGER`: Externer Port (Standard: 443)
- `-s, --protocol [http|https]`: Forward Scheme (Standard: http)
- `-w, --websockets / -nw, --no-websockets`: Websockets aktivieren
- `--email TEXT`: E-Mail für LetsEncrypt Benachrichtigungen
- `-o, --overwrite`: Bestehende Konfiguration überschreiben

**Beispiele:**

```bash
# Minimale Angaben
nrp add api.example.com -i 192.168.1.10 -p 8080

# Mit Websockets
nrp add ws.example.com -i 192.168.1.20 -p 3000 -w

# Eigener Port mit HTTPS Backend
nrp add secure.example.com -i 192.168.1.30 -p 8443 -e 9443 -s https

# Mit E-Mail für Zertifikate
nrp add example.com -i 192.168.1.10 -p 8080 --email admin@example.com
```

### `nrp remove`

Entfernt einen Proxy-Host.

```bash
nrp remove FQDN [--keep-cert]
```

**Optionen:**
- `--keep-cert`: Zertifikat behalten (nicht löschen)

**Beispiel:**

```bash
nrp remove example.com
nrp remove example.com --keep-cert
```

### `nrp list`

Zeigt alle konfigurierten Proxy-Hosts.

```bash
nrp list
```

### `nrp status`

Zeigt den Status von NGINX und Zertifikaten.

```bash
nrp status [-d, --detailed]
```

**Optionen:**
- `-d, --detailed`: Zeigt detaillierte Informationen

### `nrp remote-setup`

Konfiguriert Remote-Ausführung via SSH.

```bash
sudo nrp remote-setup [OPTIONS]
```

**Optionen:**
- `-u, --user TEXT`: Benutzername (Standard: autonginx)
- `-s, --script-path TEXT`: Installationspfad (Standard: /opt/NGINX-Reverseproxy)
- `-k, --public-key TEXT`: Pfad zum öffentlichen SSH-Schlüssel

**Beispiel:**

```bash
sudo nrp remote-setup --user myuser --public-key ~/.ssh/id_ed25519.pub
```

## Secure Remote Execution

Die sichere Remote-Ausführung ermöglicht es, das Tool von einem entfernten System aus zu verwenden:

### Setup auf dem Server:

```bash
sudo nrp remote-setup
```

Dieser Befehl:
1. Erstellt einen eingeschränkten Benutzer (Standard: `autonginx`)
2. Richtet SSH-Zugriff mit Key-Authentifizierung ein
3. Gewährt sudo-Rechte nur für den `nrp` Befehl
4. Keine Passwortabfrage nötig (NOPASSWD)

### Verwendung vom Remote-System:

```bash
# Hosts auflisten
ssh -i ~/.ssh/id_ed25519 autonginx@reverseproxy.example.com "sudo nrp list"

# Neuen Host hinzufügen
ssh -i ~/.ssh/id_ed25519 autonginx@reverseproxy.example.com \
  "sudo nrp add api.example.com -i 192.168.1.10 -p 8080"

# Host entfernen
ssh -i ~/.ssh/id_ed25519 autonginx@reverseproxy.example.com \
  "sudo nrp remove api.example.com"
```

## Konfiguration

### Verzeichnisse

- NGINX Konfigurationen: `/etc/nginx/conf.d/`
- SSL Zertifikate: `/etc/letsencrypt/live/`
- HTML Ressourcen: `/usr/share/nginx/html/`
- Dummy SSL Zertifikat: `/etc/nginx/ssl/`

### Beispiel einer generierten Konfiguration

**Mit Standard-Port 443:**

```nginx
server {
    listen 80;
    server_name example.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name example.com;

    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    client_max_body_size 100M;

    location / {
        proxy_pass http://192.168.1.10:8080/;
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Scheme $scheme;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Real-IP $remote_addr;

        # Websocket Header (wenn aktiviert)
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $http_connection;
        proxy_http_version 1.1;
    }
}
```

## Fehlerbehebung

### NGINX Konfiguration testen

```bash
nginx -t
```

### NGINX Logs anzeigen

```bash
# Error Log
tail -f /var/log/nginx/error.log

# Access Log
tail -f /var/log/nginx/access.log
```

### NGINX Status prüfen

```bash
systemctl status nginx

# Oder mit nrp
nrp status
```

### Zertifikate manuell erneuern

```bash
certbot renew
```

## Migration von v1 (Bash-Skripte)

Die alten Bash-Skripte befinden sich im `legacy/` Verzeichnis zur Referenz.

Siehe [MIGRATION.md](MIGRATION.md) für detaillierte Migrationsanleitung.

**Befehlsvergleich:**

| Alt | Neu |
|-----|-----|
| `./management.sh` | `nrp add` |
| `./setup.sh` | `sudo nrp setup` |
| `./setup_for_remote_execution.sh` | `sudo nrp remote-setup` |

## Entwicklung

### Entwicklungsumgebung einrichten

```bash
# Repository klonen
git clone https://github.com/SoftENGINE-IT/NGINX-Reverseproxy.git
cd NGINX-Reverseproxy

# Virtual Environment erstellen
python -m venv venv
source venv/bin/activate  # Oder auf Windows: venv\Scripts\activate

# Im Entwicklungsmodus installieren
pip install -e ".[dev]"
```

### Tests ausführen

```bash
pytest
```

### Code formatieren

```bash
black nrp/
```

## Projektstruktur

```
NRPv2/
├── nrp/                          # Python Package
│   ├── __init__.py
│   ├── cli.py                    # CLI Entry Point
│   ├── config.py                 # Konfiguration
│   ├── commands/                 # CLI Commands
│   │   ├── add.py
│   │   ├── remove.py
│   │   ├── list_cmd.py
│   │   ├── status.py
│   │   ├── setup.py
│   │   └── remote_setup.py
│   ├── core/                     # Core Funktionalität
│   │   ├── nginx.py
│   │   ├── certbot.py
│   │   └── validation.py
│   └── templates/                # Jinja2 Templates
│       ├── nginx_standard.conf.j2
│       ├── nginx_custom_port.conf.j2
│       ├── catch-all.conf.j2
│       └── 404.html
├── legacy/                       # Alte Bash Scripts
├── tests/                        # Unit Tests
├── pyproject.toml                # Python Packaging
├── requirements.txt
├── README.md
├── MIGRATION.md
└── LICENSE
```

## Lizenz

MIT License - siehe [LICENSE](LICENSE) Datei.

## Support

Bei Problemen oder Fragen:
- GitHub Issues: https://github.com/SoftENGINE-IT/NGINX-Reverseproxy/issues
- E-Mail: info@softengine-it.de

## Autor

**SoftENGINE IT**
- Website: https://www.softengine-it.de
- GitHub: https://github.com/SoftENGINE-IT
