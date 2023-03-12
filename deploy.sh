#!/bin/bash

# Collection of scripts to deploy a server hosting several open-source games
# Copyright (C) 2022  Jarno van der Kolk
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

### Deploy script for a game server running multiple open-source game servers
### This script is intended for Debian 11, but may work on other apt-based
### systems too
###
### Specify domain name:
###   DOMAINNAME=example.com HOSTEDBYNAME=DeathByDenim ./deploy.sh

set -e

if [ -z $DOMAINNAME ]; then
  echo "Domain name was not set. Please export DOMAINNAME first"
  exit 1
fi
if [ -z $HOSTEDBYNAME ]; then
  echo "Hosted-by name was not set. Please export HOSTEDBYNAME first"
  exit 1
fi

export stk_version="latest"
export bzflag_version="2.4"
export mindustry_version="latest"
export odamex_version="latest"
export openhv_version="latest"
export teeworlds_version="latest"
export teeworldsddrace_version="16.1"
export unvanquished_version="latest"
export xonotic_version="0.8.5"
export lix_version="latest"
export shatteredparadise_version="latest"

export systemuser="onfoss"
export letsencryptemail="jarno@jarno.ca"

# Store the randomly generated password. This is used for the web interface
# as well as for admin access for the game servers
if [ -f /etc/gameserverpassword ]; then
  export systempassword=$(cat /etc/gameserverpassword)
else
  export systempassword="$(< /dev/urandom tr -dc a-z | head -c${1:-8};echo;)"
  echo "$systempassword" > /etc/gameserverpassword
  chmod go= /etc/gameserverpassword
fi

# Install what we need
apt update -y && apt full-upgrade -y
apt install --assume-yes \
  git tmux unzip curl vim openjdk-11-jdk xz-utils python3-venv python3-pip \
  python3-dev apt virtualenv python3-virtualenv libjpeg-dev zlib1g-dev \
  fuse g++ gcc curl firewalld automake autoconf libtool \
  libcurl3-dev libc-ares-dev zlib1g-dev libncurses-dev make python3-aiohttp \
  nginx-core certbot python3-certbot-nginx sudo python3-psutil \
  ldc dub libenet-dev python3-bcrypt jq telnet jekyll

# Create the user for running the game servers
if ! getent passwd ${systemuser}; then
  useradd ${systemuser} --system --create-home --shell=/bin/false
fi
export systemuserhome="$( getent passwd "${systemuser}" | cut -d: -f6 )"

# Install the web interface for servers that require interactive shells
if [ -d console2web ]; then
  cd console2web
  git pull
  cd -
else
  git clone https://github.com/DeathByDenim/console2web.git
fi
cp console2web/console2web.py /usr/bin/console2web

# Deploy web interface stuff
"$(dirname "$0")"/scripts/deploy_monitoring.sh
"$(dirname "$0")"/scripts/deploy_webserver.sh

# Deploy the game servers
"$(dirname "$0")"/scripts/deploy_supertuxkart.sh
"$(dirname "$0")"/scripts/deploy_bzflag.sh
"$(dirname "$0")"/scripts/deploy_hedgewars.sh
"$(dirname "$0")"/scripts/deploy_lix.sh
"$(dirname "$0")"/scripts/deploy_mindustry.sh
"$(dirname "$0")"/scripts/deploy_minetest.sh
"$(dirname "$0")"/scripts/deploy_odamex.sh
"$(dirname "$0")"/scripts/deploy_openhv.sh
"$(dirname "$0")"/scripts/deploy_openspades.sh
"$(dirname "$0")"/scripts/deploy_teeworlds.sh
"$(dirname "$0")"/scripts/deploy_teeworlds-ddrace.sh
"$(dirname "$0")"/scripts/deploy_unvanquished.sh
"$(dirname "$0")"/scripts/deploy_xonotic.sh
"$(dirname "$0")"/scripts/deploy_xonotic-br.sh
"$(dirname "$0")"/scripts/deploy_armagetron_advanced.sh
"$(dirname "$0")"/scripts/deploy_opensoldat.sh
"$(dirname "$0")"/scripts/deploy_supertuxparty.sh
"$(dirname "$0")"/scripts/deploy_ufoai.sh
"$(dirname "$0")"/scripts/deploy_shatteredparadise.sh

# Apply all pending firewall rules. NGINX shouldn't have to be restarted, but it seems to help.
firewall-cmd --reload
systemctl restart nginx

echo
echo "Installation complete. Password is ${systempassword}"
