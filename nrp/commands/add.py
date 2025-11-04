"""
Add command - Create new proxy host
"""
import click
from pathlib import Path

from nrp.core.validation import (
    validate_fqdn,
    validate_ip,
    validate_port,
    validate_protocol,
    validate_config_exists
)
from nrp.core.nginx import NginxManager
from nrp.core.certbot import CertbotManager
from nrp.config import NGINX_CONF_DIR


@click.command()
@click.argument('fqdn', required=False)
@click.option('--internal-ip', '-i', help='Interne IP-Adresse des Servers')
@click.option('--internal-port', '-p', type=int, help='Interner Port des Servers')
@click.option('--external-port', '-e', type=int, default=443, help='Externer Port (Standard: 443)')
@click.option('--protocol', '-s', type=click.Choice(['http', 'https'], case_sensitive=False), default='http', help='Forward Scheme (http oder https)')
@click.option('--websockets/--no-websockets', '-w/-nw', default=False, help='Websockets aktivieren')
@click.option('--email', help='E-Mail für LetsEncrypt Benachrichtigungen')
@click.option('--overwrite', '-o', is_flag=True, help='Bestehende Konfiguration überschreiben')
def add(fqdn, internal_ip, internal_port, external_port, protocol, websockets, email, overwrite):
    """
    Erstellt einen neuen Proxy-Host

    Beispiele:

        nrp add example.com -i 192.168.1.10 -p 8080

        nrp add test.example.com -i 192.168.1.20 -p 3000 -e 8443 -s https -w

        nrp add (interaktiv)
    """
    nginx = NginxManager()
    certbot = CertbotManager()

    # Interactive mode if no FQDN provided
    if not fqdn:
        fqdn = click.prompt('FQDN (z.B. server.example.com)', type=str)

    # Validate FQDN
    if not validate_fqdn(fqdn):
        click.echo(click.style(f'Ungültiger FQDN: {fqdn}', fg='red'))
        return

    # Check if config already exists
    if validate_config_exists(fqdn, NGINX_CONF_DIR):
        if not overwrite:
            choice = click.prompt(
                f'Konfiguration für {fqdn} existiert bereits. Überschreiben?',
                type=click.Choice(['j', 'n'], case_sensitive=False),
                default='n'
            )
            if choice == 'n':
                click.echo('Abgebrochen.')
                return
        # Remove old config
        nginx.remove_config(fqdn)

    # Get remaining parameters interactively if not provided
    if not internal_ip:
        internal_ip = click.prompt('Interne IP-Adresse', type=str)

    if not validate_ip(internal_ip):
        click.echo(click.style(f'Ungültige IP-Adresse: {internal_ip}', fg='red'))
        return

    if not internal_port:
        internal_port = click.prompt('Interner Port', type=int, default=8080)

    if not validate_port(internal_port):
        click.echo(click.style(f'Ungültiger Port: {internal_port}', fg='red'))
        return

    if external_port and not validate_port(external_port):
        click.echo(click.style(f'Ungültiger externer Port: {external_port}', fg='red'))
        return

    # Ask for websockets if not specified
    if websockets is None:
        websockets = click.confirm('Websockets aktivieren?', default=False)

    click.echo(f'\nErstelle Proxy-Host für {fqdn}...')

    # Step 1: Create temporary HTTP config
    click.echo('Erstelle temporäre HTTP-Konfiguration...')
    nginx.create_temp_config(fqdn, external_port)

    if not nginx.reload():
        click.echo(click.style('Fehler beim Neuladen der NGINX-Konfiguration', fg='red'))
        return

    # Step 2: Request SSL certificate
    click.echo('Fordere SSL-Zertifikat an...')
    if not certbot.request_certificate(fqdn, email):
        click.echo(click.style('Fehler bei der Zertifikatsanforderung', fg='red'))
        nginx.remove_config(fqdn)
        nginx.reload()
        return

    # Step 3: Create final configuration
    click.echo('Erstelle finale HTTPS-Konfiguration...')
    nginx.create_config(
        fqdn=fqdn,
        internal_ip=internal_ip,
        internal_port=internal_port,
        external_port=external_port,
        forward_scheme=protocol.lower(),
        websockets_enabled=websockets
    )

    # Step 4: Test and reload
    if not nginx.test_config():
        click.echo(click.style('NGINX-Konfiguration ist ungültig', fg='red'))
        return

    if not nginx.reload():
        click.echo(click.style('Fehler beim Neuladen der NGINX-Konfiguration', fg='red'))
        return

    click.echo(click.style(f'\n✓ Proxy-Host {fqdn} erfolgreich erstellt!', fg='green'))
    click.echo(f'\nKonfiguration: /etc/nginx/conf.d/{fqdn}.conf')
    click.echo(f'Zertifikat: /etc/letsencrypt/live/{fqdn}/')
