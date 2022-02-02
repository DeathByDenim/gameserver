#!/bin/bash

### Deploy script for a game server running multiple open-source game servers
### This script is intended for Debian 11, but may work on other apt-based
### systems too

set -e

export stk_version="1.3"
export bzflag_version="2.4"
export mindustry_version="135"
export openhv_version="20220102"
export teeworlds_version="0.7.5"
export unvanquished_version="0.52.1"
export xonotic_version="0.8.2"

export systemuser="onfoss"

# Install what we need
apt update -y && apt full-upgrade -y
apt install --assume-yes \
  git tmux unzip curl vim openjdk-11-jdk xz-utils python3-venv python3-pip \
  python3-dev apt virtualenv python3-virtualenv libjpeg-dev zlib1g-dev \
  fuse hedgewars g++ gcc curl firewalld automake autoconf libtool \
  libcurl3-dev libc-ares-dev zlib1g-dev libncurses-dev make python3-aiohttp \
  nginx-core certbot python3-certbot-nginx sudo

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

# Deploy the game servers
"$(dirname "$0")"/scripts/deploy_supertuxkart.sh
"$(dirname "$0")"/scripts/deploy_bzflag.sh
"$(dirname "$0")"/scripts/deploy_hedgewars.sh
"$(dirname "$0")"/scripts/deploy_mindustry.sh
"$(dirname "$0")"/scripts/deploy_openhv.sh
"$(dirname "$0")"/scripts/deploy_openspades.sh
"$(dirname "$0")"/scripts/deploy_teeworlds.sh
"$(dirname "$0")"/scripts/deploy_unvanguished.sh
"$(dirname "$0")"/scripts/deploy_xonotic.sh

# Web dashboard
systemctl enable --now nginx

firewall-cmd --zone=public --add-service=http --permanent
firewall-cmd --zone=public --add-service=https --permanent
firewall-cmd --reload

certbot -n --nginx -d ${LINODE_ID} -d www.${LINODE_ID} --agree-tos -m jarno@jarno.ca

cp -r "$(dirname "$0")"/website/* /var/www/html
