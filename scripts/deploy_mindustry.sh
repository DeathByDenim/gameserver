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

if [ -e /etc/systemd/system/mindustry.service ]; then
  systemctl stop mindustry
fi

if [ -z ${mindustry_version} ] || [ "${mindustry_version}" = "latest" ]; then
  mindustry_version=$(curl -s https://api.github.com/repos/Anuken/Mindustry/releases?per_page=1 | jq -r '.[0]["tag_name"]' | cut -c2-)
fi

# Mindustry
mkdir -p /opt/mindustry-${mindustry_version}
curl --location https://github.com/Anuken/Mindustry/releases/download/v${mindustry_version}/server-release.jar > /opt/mindustry-${mindustry_version}/mindustry.jar
mkdir -p /var/lib/mindustry
chown -R ${systemuser} /var/lib/mindustry

cat > /etc/systemd/system/mindustry.service <<EOF
[Unit]
Description=Mindustry server
After=network.target

[Service]
WorkingDirectory=/var/lib/mindustry
ExecStart=/usr/bin/console2web -a "${systempassword}" -p 62548 /usr/lib/jvm/java-11-openjdk-amd64/bin/java -jar /opt/mindustry-${mindustry_version}/mindustry.jar "config autosave true","config autosaveSpacing 120","host"
Restart=on-failure
User=${systemuser}

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now mindustry.service

cat > /etc/nginx/gameserver.d/mindustry.conf <<EOF
location /mindustry {
    proxy_pass http://localhost:62548/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "Upgrade";
    proxy_set_header Host \$host;
}
EOF

firewall-cmd --zone=public --add-port=6567/tcp --permanent
firewall-cmd --zone=public --add-port=6567/udp --permanent
