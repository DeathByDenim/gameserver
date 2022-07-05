# Game server

This is a collection of scripts to deploy game servers on Debian 11. All game
servers are wrapped in SystemD units and can be controlled by systemctl.

It also comes with a web front end which features the games hosted as well as
their respective download link. It also displays server stats and has an admin
panel for game servers that have interactive shells.

The following games are deployed:

* Bzflag
* Hedgewars
* Lix
* Mindustry
* OpenHV
* OpenSpades
* Soldat
* SuperTuxKart
* Super Tux Party
* Teeworlds (optionally as DDrace)
* Unvanquished
* Xonotic (optionally as Battle Royale)

It is based on https://git.libregaming.org/c/onFOSS-LAN-Serverconfiguration

## Installation

The main script is `deploy.sh`. You only need to give if your domain name and your own name.
```
DOMAINNAME=play.jarno.ca  HOSTEDBYNAME=DeathByDenim ./deploy.sh
```
This will download all the game servers, install them, configure them, and start them up. It also retrieves a certificate for Let's Encrypt for the web interface. If you don't want the certificate, you can also specify `NOSSL=1`.

There is also support for generating just the website without the game server which is useful if you want to host the website somewhere else while your main server is down.
```
DOMAINNAME=play.jarno.ca HOSTEDBYNAME=DeathByDenim ./pack_web_offline.sh
```
The webpage will display "OFFLINE" and not attempt to show the server stats.

The password for the admin panel as well as for game servers that support admin password is stored in `/etc/gameserverpassword`. The username for the admin panel is just `onfoss`.
