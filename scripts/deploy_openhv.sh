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

if [ -e /etc/systemd/system/openhv.service ]; then
  systemctl stop openhv
fi

if [ -z ${openhv_version} ] || [ "${openhv_version}" = "latest" ]; then
  openhv_version=$(curl -s https://api.github.com/repos/OpenHV/OpenHV/releases/latest | jq -r '.["tag_name"]')
fi

# Install OpenHV
mkdir -p /opt/openhv-${openhv_version}
curl --location "https://github.com/OpenHV/OpenHV/releases/download/${openhv_version}/OpenHV-${openhv_version}-x86_64.AppImage" > /opt/openhv-${openhv_version}/OpenHV-x86_64.AppImage
chmod +x /opt/openhv-${openhv_version}/OpenHV-x86_64.AppImage

cat > /etc/systemd/system/openhv.service <<EOF
[Unit]
Description=OpenHV server
After=network.target

[Service]
ExecStart=/opt/openhv-${openhv_version}/OpenHV-x86_64.AppImage --server Server.Name="OnFOSS" Server.ListenPort=1234 Server.AdvertiseOnline=False
Restart=on-failure
User=${systemuser}

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now openhv.service

# Add firewall rules
firewall-cmd --zone=public --add-port=1234/tcp --permanent
