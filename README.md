# Game server

This is a collection of scripts to deploy game servers on Debian 11. All game
servers are wrapped in SystemD units and can be controlled by systemctl.

It also comes with a web front end which features the games hosted as well as
their respective download link. It also displays server stats and has an admin
panel for game servers that have interactive shells.

The following games are deployed:

* Bzflag
* Hedgewars
* Mindustry
* OpenHV
* OpenSpades
* SuperTuxKart
* Teeworlds
* Unvanquished
* Xonotic

It is based on https://git.libregaming.org/c/onFOSS-LAN-Serverconfiguration

## Installation

The main script is `deploy.sh`. You only need to give if your domain name
```
DOMAINNAME=play.jarno.ca ./deploy.sh
```
This will download all the game servers, install them, configure them, and start them up. It also retrieves a certificate for Let's Encrypt for the web interface.
