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

set -e

if [ -e /etc/systemd/system/odamex.service ]; then
  systemctl stop odamex
fi

# Install ODAMEX
apt install --assume-yes libsdl2-dev libsdl2-mixer-dev cmake deutex freedoom
mkdir -p ${TMPDIR:-/tmp}/odamex-build
curl --location https://downloads.sourceforge.net/project/odamex/Odamex/${odamex_version}/odamex-src-${odamex_version}.tar.xz | tar --extract --xz --no-same-owner --directory="${TMPDIR:-/tmp}/odamex-build"
mkdir ${TMPDIR:-/tmp}/odamex-build/odamex-src-${odamex_version}/build
cd ${TMPDIR:-/tmp}/odamex-build/odamex-src-${odamex_version}/build
cmake -DBUILD_CLIENT=OFF -DBUILD_LAUNCHER=OFF -DCMAKE_INSTALL_PREFIX=/opt/odamex-${odamex_version} ..
make
make install
cd -
rm -rf ${TMPDIR:-/tmp}/odamex-build

# Ugh, these links expire. Always need to download manually
# if curl --location 'https://www.moddb.com/downloads/mirror/189782/123/ec702ae81b867d6096c396335fbff692/?referer=https%3A%2F%2Fwww.moddb.com%2Fmods%2Fdoom-christmas-for-doom-ii-final-doom' > ${TMPDIR:-/tmp}/doomxmas.zip; then
#   unzip -o -d /usr/share/games/doom/ ${TMPDIR:-/tmp}/doomxmas.zip
# fi

proto="http"
if [ x"$NOSSL" = "x" ] || [ $NOSSL -ne 1 ]; then
  proto="https"
fi

mkdir -p /home/${systemuser}/.odamex/
cat > /home/${systemuser}/.odamex/odasrv.cfg <<EOF
set sv_hostname "OnFOSS LAN"
set sv_motd "Welcome to OnFOSS LAN DOOM server"
set sv_website "${proto}://${DOMAINNAME}/"
set sv_downloadsites "${proto}://${DOMAINNAME}/wads/"
set rcon_password "${systempassword}"
set sv_gametype "0"
set sv_skill "5"
set sv_maxplayers "32"
set sv_monstersrespawn 1
set sv_warmup 1
set sv_countdown 5
wad doomxmas.wad
EOF
chown -R ${systemuser}: /home/${systemuser}/.odamex/

# Create SystemD unit
cat > /etc/systemd/system/odamex.service <<EOF
[Unit]
Description=ODAMEX server
After=network.target

[Service]
ExecStart=/opt/odamex-${odamex_version}/bin/odasrv
Restart=on-failure
User=${systemuser}

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now odamex.service

# Add firewall rules
firewall-cmd --zone=public --add-port=10666/udp --permanent
