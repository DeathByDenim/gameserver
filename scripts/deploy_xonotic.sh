#!/bin/bash
set -e

# Xonotic
xonotic_directory="/opt/xonotic-${xonotic_version}"
curl --location https://dl.xonotic.org/xonotic-${xonotic_version}.zip > ${TMPDIR:-/tmp}/xonotic.zip
mkdir -p "${xonotic_directory}"
unzip -f -o -d ${xonotic_directory} ${TMPDIR:-/tmp}/xonotic.zip
rm -f ${TMPDIR:-/tmp}/xonotic.zip

cat > /etc/xonotic.cfg <<EOF
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

cat > /etc/systemd/system/xonoto.service <<EOF
[Unit]
Description=Unvanguished server
After=network.target

[Service]
WorkingDirectory=${xonotic_directory}
ExecStart=${xonotic_directory}daemonded -pakpath ${unvanquished_directory}/share/pkg/ -libpath ${unvanquished_directory}/bin/ -homepath \${HOME}/unvanguished_home/ +exec unvanguished.cfg
Restart=on-failure
User=${systemuser}

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now xonoto.service

firewall-cmd --zone=public --add-port=26000/udp --permanent
