# Changelog

Alle wichtigen Änderungen an diesem Projekt werden in dieser Datei dokumentiert.

## [2.2.1] - 2025

### Bugfix

- **Shell-Completion**
Die Shell Completion führte zu Fehlern wegen eines falschen aufruf des python click Parameters.
  - Vorher (falsch):
    @click.argument('fqdn', autocompletion=complete_domains)

  - Jetzt (richtig):
    @click.argument('fqdn', shell_complete=complete_domains)

## [2.2.0] - 2025

### Hinzugefügt

- **Neue CLI-Befehle**
  - `nrp completion` - Hinzufügen von Shell completion für Befehle und Optionen

## [2.1.0] - 2025

### Hinzugefügt

- **Neue add Option**
  - `--full-interactive` - frägt bei einem reinen `nrp add` alle Optionen ab

- **Verbesserungen**
  - Symlink bei der Instalaltion für ein Ausführen des Tools ohne aktives venv 

### Verbeserungen
## [2.0.0] - 2025

### Hinzugefügt

- **Komplette Neuimplementierung in Python**
  - Modernes CLI-Tool mit Click Framework
  - Jinja2 Templates für flexible Konfigurationen
  - Automatische Input-Validierung (FQDN, IP, Ports)
  - Unit Tests mit pytest

- **Neue CLI-Befehle**
  - `nrp add` - Proxy-Host hinzufügen (interaktiv oder mit Parametern)
  - `nrp remove` - Proxy-Host entfernen
  - `nrp list` - Alle Hosts auflisten
  - `nrp status` - Status anzeigen
  - `nrp setup` - System Setup
  - `nrp remote-setup` - Remote Execution Setup

- **Verbesserungen**
  - Bessere Fehlerbehandlung
  - Farbige Terminal-Ausgaben
  - Interaktive und nicht-interaktive Modi
  - Optionale E-Mail für LetsEncrypt
  - Flexible Port-Konfiguration
  - HSTS Header standardmäßig aktiviert

- **Entwicklung**
  - Modern Python Packaging (pyproject.toml)
  - pip-Installation möglich
  - Entwicklungsmodus (`pip install -e .`)
  - Code-Formatierung mit Black
  - Type Hints

### Geändert

- Migration von Bash-Skripten zu Python
- Vereinfachte Befehlsstruktur
- Verbesserte Dokumentation

### Migration von v1.x

Die alten Bash-Skripte befinden sich im `legacy/` Verzeichnis zur Referenz.

| Alt (v1) | Neu (v2) |
|----------|----------|
| `./management.sh` | `nrp add` |
| `./setup.sh` | `sudo nrp setup` |
| `./setup_for_remote_execution.sh` | `sudo nrp remote-setup` |

Siehe [MIGRATION.md](MIGRATION.md) für detaillierte Anleitung.

## [1.x] - Legacy

Bash-basierte Implementation (siehe `legacy/` Verzeichnis)
