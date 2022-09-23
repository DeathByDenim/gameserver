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

apt install --assume-yes hedgewars

if [ -e /etc/systemd/system/hedgewars.service ]; then
  systemctl stop hedgewars
fi

# Hedgewars
# Create SystemD unit
cat > /etc/systemd/system/hedgewars.service <<EOF
[Unit]
Description=Hedgewars server
After=network-online.target

[Service]
ExecStart=/usr/lib/hedgewars/bin/hedgewars-server
Restart=on-failure
User=${systemuser}

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now hedgewars.service

# Add firewall rules
firewall-cmd --zone=public --add-port=46631/tcp --permanent
