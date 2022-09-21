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

if [ -e /lib/systemd/system/ufoai-server.service ]; then
  systemctl stop ufoai-server
fi

apt install --assume-yes ufoai-server

# Bug fix for UFO:AI? WorkingDirectory needs to be set for server
# to be able to read debian_server.cfg
mkdir -p /etc/systemd/system/ufoai-server.service.d
cat > /etc/systemd/system/ufoai-server.service.d/override.conf <<EOF
[Service]
WorkingDirectory=/usr/lib/ufoai-server
EOF
systemctl daemon-reload

cat > /etc/ufoai-server/server.cfg <<EOF
set sv_hostname "onFOSS-LAN"
set sv_maxclients 8
set sv_public 0
set sv_gametype "coop4"
set rcon_password "${systempassword}"
mapcyclenext
EOF

systemctl restart ufoai-server.service

# Add firewall rules
firewall-cmd --zone=public --add-port=27910/tcp --permanent
