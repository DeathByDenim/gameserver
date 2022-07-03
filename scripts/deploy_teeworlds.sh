#!/bin/bash
set -e

if [ -e /etc/systemd/system/teeworlds.service ]; then
  systemctl stop teeworlds
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
sv_spectator_slots 16

sv_register 0

sv_rcon_password onFOSS

sv_vote_kick 1
sv_vote_map 1

sv_maprotation dm2,dm3,dm6,dm7

add_vote "Restart Round" "restart"
add_vote "Reload Map" "reload"
add_vote "Change Gamemode to DM" "exec dm.cfg"
add_vote "Change Gamemode to CTF" "exec ctf.cfg"
add_vote "Change Gamemode to TDM" "exec tdm.cfg"
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

cat > /etc/systemd/system/teeworlds.service <<EOF
[Unit]
Description=Teeworlds server
After=network.target
Conflicts=teeworlds-ddrace.service

[Service]
ExecStart=${teeworld_directory}/teeworlds_srv -f /etc/teeworlds.cfg
Restart=on-failure
User=${systemuser}

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now teeworlds.service

firewall-cmd --zone=public --add-port=8303/udp --permanent
