# Legacy Bash Scripts

Diese Verzeichnis enthält die alten Bash-Skripte zur Referenz.

**Diese Skripte sind veraltet und werden durch das neue Python CLI-Tool `nrp` ersetzt.**

## Migration

Alte Befehle → Neue Befehle:

- `./management.sh` → `nrp` (interaktiv)
- `./setup.sh` → `sudo nrp setup`
- `./setup_for_remote_execution.sh` → `sudo nrp remote-setup`
- `./management.sh domain.com 192.168.1.10 http n 8080 443` → `nrp add domain.com -i 192.168.1.10 -p 8080`

## Dateien

- `management.sh` - Alte Management-Skript
- `setup.sh` - Alte Setup-Skript
- `setup_for_remote_execution.sh` - Alte Remote-Setup-Skript
