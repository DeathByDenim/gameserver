#!/bin/bash

### Deploy script for a game server running multiple open-source game servers
### This script is intended for Debian 11, but may work on other apt-based
### systems too
###
### Specify domain name:
###   DOMAINNAME=example.com ./deploy.sh

set -e

if [ -z $DOMAINNAME ]; then
  echo "Domain name was not set. Please export DOMAINNAME first"
  exit 1
fi

export stk_version="1.3"
export bzflag_version="2.4"
export mindustry_version="135"
export openhv_version="20220128"
export teeworlds_version="0.7.5"
export unvanquished_version="0.52.1"
export xonotic_version="0.8.2"
export lix_version="0.9.41"

export systemuser="onfoss"
export letsencryptemail="jarno@jarno.ca"
export systempassword="$(< /dev/urandom tr -dc a-z | head -c${1:-8};echo;)"

# Store the randomly generated password. This is used for the web interface
# as well as for admin access for the game servers
echo "$systempassword" > /etc/gameserverpassword
chmod go= /etc/gameserverpassword

# Install what we need
apt update -y && apt full-upgrade -y
apt install --assume-yes \
  git tmux unzip curl vim openjdk-11-jdk xz-utils python3-venv python3-pip \
  python3-dev apt virtualenv python3-virtualenv libjpeg-dev zlib1g-dev \
  fuse g++ gcc curl firewalld automake autoconf libtool \
  libcurl3-dev libc-ares-dev zlib1g-dev libncurses-dev make python3-aiohttp \
  nginx-core certbot python3-certbot-nginx sudo python3-psutil \
  ldc dub libenet-dev

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
"$(dirname "$0")"/scripts/deploy_lix.sh
"$(dirname "$0")"/scripts/deploy_mindustry.sh
"$(dirname "$0")"/scripts/deploy_openhv.sh
"$(dirname "$0")"/scripts/deploy_openspades.sh
"$(dirname "$0")"/scripts/deploy_teeworlds.sh
"$(dirname "$0")"/scripts/deploy_unvanquished.sh
"$(dirname "$0")"/scripts/deploy_xonotic.sh

# Deploy web interface stuff
"$(dirname "$0")"/scripts/deploy_monitoring.sh
"$(dirname "$0")"/scripts/deploy_webserver.sh

echo
echo "Installation complete. Password is ${systempassword}"
