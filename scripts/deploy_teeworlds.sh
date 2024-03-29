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

if [ -e /etc/systemd/system/teeworlds.service ]; then
  systemctl stop teeworlds
fi

if [ -z ${teeworlds_version} ] || [ "${teeworlds_version}" = "latest" ]; then
  teeworlds_version=$(curl -s https://api.github.com/repos/teeworlds/teeworlds/releases/latest | jq -r '.["tag_name"]')
fi

# Teeworlds
teeworld_directory="/opt/teeworlds-${teeworlds_version}"
mkdir -p ${teeworld_directory}
curl --location "https://github.com/teeworlds/teeworlds/releases/download/${teeworlds_version}/teeworlds-${teeworlds_version}-linux_x86_64.tar.gz" | tar --extract --gzip --no-same-owner --strip-components=1 --directory="${teeworld_directory}"

cat > /etc/teeworlds.cfg <<EOF
sv_name onFOSS
sv_map dm3
sv_scorelimit 20
sv_timelimit 10
sv_gametype dm
sv_motd "HAVE FUN!\nTo change the gamemode you have to reload or change the map to apply the change.\n\n${DOMAINNAME}"
sv_max_clients 64
sv_player_slots 48

sv_register 0

ec_port 8123
ec_password ${systempassword}
sv_rcon_password ${systempassword}

sv_vote_kick 1

sv_maprotation dm2,dm3,dm6,dm7

add_vote "Restart Round" "restart"
add_vote "Reload Map" "reload"
add_vote "Change Gamemode to DM" "exec /etc/teedm.cfg"
add_vote "Change Gamemode to CTF" "exec /etc/teectf.cfg"
add_vote "Change Gamemode to TDM" "exec /etc/teetdm.cfg"
add_vote "Change Map to ctf1" "change_map ctf1"
add_vote "Change Map to ctf2" "change_map ctf2"
add_vote "Change Map to ctf3" "change_map ctf3"
add_vote "Change Map to ctf4" "change_map ctf4"
add_vote "Change Map to ctf5" "change_map ctf5"
add_vote "Change Map to dm1" "change_map dm1"
add_vote "Change Map to dm2" "change_map dm2"
add_vote "Change Map to dm6" "change_map dm6"
add_vote "Change Map to dm7" "change_map dm7"
add_vote "Change Map to dm8" "change_map dm8"
add_vote "Change Map to dm9" "change_map dm9"
EOF

cat > /etc/teedm.cfg <<EOF
sv_maprotation dm2,dm3,dm6,dm7
sv_map dm3
sv_scorelimit 20
sv_gametype dm
EOF

cat > /etc/teetdm.cfg <<EOF
sv_maprotation dm2,dm3,dm6,dm7
sv_map dm3
sv_scorelimit 20
sv_gametype dm
EOF

cat > /etc/teectf.cfg <<EOF
sv_maprotation ctf2,ctf3,ctf4
sv_map ctf2
sv_scorelimit 400
sv_gametype ctf
EOF

cat > /etc/systemd/system/teeworlds.service <<EOF
[Unit]
Description=Teeworlds server
After=network.target
Conflicts=teeworlds-ddrace.service
Requires=teeworlds-rcon.service

[Service]
ExecStart=${teeworld_directory}/teeworlds_srv -f /etc/teeworlds.cfg
Restart=on-failure
User=${systemuser}

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/teeworlds-rcon.service <<EOF
[Unit]
Description=Teeworlds server rcon
After=teeworlds.service
Requires=teeworlds.service
Conflicts=teeworlds-ddrace-rcon.service

[Service]
ExecStart=/usr/bin/console2web -a "${systempassword}" -p 62552 -b "${systempassword}" telnet localhost 8123
Restart=on-failure
User=${systemuser}

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now teeworlds.service

cat > /etc/nginx/gameserver.d/teeworlds.conf <<EOF
location /teeworlds {
    proxy_pass http://localhost:62552/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "Upgrade";
    proxy_set_header Host \$host;
}
EOF

firewall-cmd --zone=public --add-port=8303/udp --permanent
