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

if [ -e /etc/systemd/system/xonotic.service ]; then
  systemctl stop xonotic
fi

# Xonotic
xonotic_directory="/opt/xonotic-${xonotic_version}"
curl --location https://dl.xonotic.org/xonotic-${xonotic_version}.zip > ${TMPDIR:-/tmp}/xonotic.zip
mkdir -p "${xonotic_directory}"
unzip -o -d ${xonotic_directory} ${TMPDIR:-/tmp}/xonotic.zip
rm -f ${TMPDIR:-/tmp}/xonotic.zip

mkdir -p ${systemuserhome}/xonotic/data
chown -R ${systemuser}: ${systemuserhome}/xonotic

cat > ${systemuserhome}/xonotic/data/server.cfg <<EOF
sv_public 0
hostname "onFOSS"
maxplayers 64
port 26000
log_file "server.log"
g_start_delay 15
g_maplist ""
g_maplist_shuffle 1
gametype dm
rcon_password "onFOSS"
bot_number 4
skill 8
minplayers 4
bot_prefix [BOT]
g_maplist_votable 6
sv_vote_gametype 1
sv_vote_gametype_options "dm tdm dom ctf ca rc nb as kh inv ka lms ons"
sv_vote_call 1
sv_weaponstats_file http://www.xonotic.org/weaponbalance/
EOF

cat > /etc/systemd/system/xonotic.service <<EOF
[Unit]
Description=Xonotic server
After=network.target
Conflicts=xonotic-br.service

[Service]
WorkingDirectory=${xonotic_directory}/Xonotic
ExecStart=/usr/bin/console2web -a "${systempassword}" -p 62550 ${xonotic_directory}/Xonotic/xonotic-linux64-dedicated +serverconfig server.cfg -userdir ${systemuserhome}/xonotic
Restart=on-failure
User=${systemuser}

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now xonotic.service

cat > /etc/nginx/gameserver.d/xonotic.conf <<EOF
location /xonotic {
    proxy_pass http://localhost:62550/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "Upgrade";
    proxy_set_header Host \$host;
}
EOF

firewall-cmd --zone=public --add-port=26000/udp --permanent
