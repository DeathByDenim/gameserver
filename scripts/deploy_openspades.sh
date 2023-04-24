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

if [ -e /etc/systemd/system/openspades.service ]; then
  systemctl stop openspades
fi

# Smallish maps from https://github.com/kinvaris/openspades-maps
## island
## nuketown (broken)
## pinpoint
## Realistic Bridge
## Rocket Island
## Submarine

# OpenSpades
mkdir -p /opt/openspades
if [ -d /opt/openspades/env ]; then
  rm -rf /opt/openspades/env
fi
virtualenv -p python3 /opt/openspades/env
source /opt/openspades/env/bin/activate
pip install -U piqueserver
pip install "twisted<21.0.0" # Twisted 22 removed getPage that piqueserver 1.0.0 depends on
pip install "MarkupSafe==2.0.1" # MarkupSafe removed soft_unicode that piqueserver 1.0.0 depends on
sudo -u ${systemuser} /opt/openspades/env/bin/piqueserver --copy-config
sudo -u ${systemuser} sed -i ${systemuserhome}/.config/piqueserver/config.toml \
  -e s/"piqueserver instance"/"onFOSS"/ \
  -e s/"#admin = \[\"adminpass1\", \"adminpass2\"\]"/"admin = \[\"${systempassword}\"\]"/ \
  -e s/"name = \"Blue\""/"name = \"Cyanide\""/ \
  -e s/"color = \[ 0, 0, 255\]"/"color = [ 0, 255, 255]"/ \
  -e s/"name = \"Green\""/"name = \"Pinkster\""/ \
  -e s/"color = \[ 0, 255, 0\]"/"color = [ 255, 0, 255]"/ \
  -e s/"  \"classicgen\","/"  \"smallrandomisland\",\n  \"island\",\n  \"pinpoint\",\n  \"realisticbridge\",\n  \"rocketisland\",\n  \"submarine\","/ \
  -e s/"default_time_limit = \"2hours\""/"default_time_limit = \"20minutes\""/
deactivate

cat > /etc/systemd/system/openspades.service <<EOF
[Unit]
Description=OpenSpades server
After=network.target

[Service]
ExecStart=/opt/openspades/env/bin/piqueserver
Restart=on-failure
User=${systemuser}

[Install]
WantedBy=multi-user.target
EOF

for map in island pinpoint realisticbridge rocketisland submarine; do
  curl "https://raw.githubusercontent.com/kinvaris/openspades-maps/master/${map}.txt" > ${systemuserhome}/.config/piqueserver/maps/${map}.txt
  curl "https://raw.githubusercontent.com/kinvaris/openspades-maps/master/${map}.vxl" > ${systemuserhome}/.config/piqueserver/maps/${map}.vxl
done
curl "https://raw.githubusercontent.com/DeathByDenim/openspades-maps/main/smallrandomisland.txt" > ${systemuserhome}/.config/piqueserver/maps/smallrandomisland.txt

systemctl daemon-reload
systemctl enable --now openspades.service

firewall-cmd --zone=public --add-port=32886/tcp --permanent
firewall-cmd --zone=public --add-port=32887/udp --permanent
