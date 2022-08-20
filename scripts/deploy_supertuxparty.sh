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

if [ -e /etc/systemd/system/supertuxparty.service ]; then
  systemctl stop supertuxparty
fi

# Install Lix
mkdir -p /opt/supertuxparty
curl 'https://supertux.party/download/latest/server.zip' > ${TMPDIR:/tmp}/server.zip
unzip -o -d /opt/supertuxparty ${TMPDIR:/tmp}/server.zip
rm ${TMPDIR:/tmp}/server.zip

# Create SystemD unit
cat > /etc/systemd/system/supertuxparty.service <<EOF
[Unit]
Description=Super Tux Party server
After=network.target

[Service]
WorkingDirectory=/opt/supertuxparty
ExecStart=/opt/supertuxparty/supertuxparty_server
Restart=on-failure
User=${systemuser}

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now supertuxparty.service

# Add firewall rules
firewall-cmd --zone=public --add-port=7634/udp --permanent
