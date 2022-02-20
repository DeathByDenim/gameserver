#!/bin/bash
set -e

if [ -e /etc/systemd/system/xonotic-br.service ]; then
  systemctl stop xonotic-br
fi

apt install --assume-yes autoconf automake build-essential curl git libtool \
  libgmp-dev libjpeg62-turbo-dev libsdl2-dev libxpm-dev xserver-xorg-dev \
  zlib1g-dev unzip zip

# Xonotic Battle Royale branch
xonotic_directory="/opt/xonotic-br"
mkdir -p "${xonotic_directory}"
git clone https://gitlab.com/xonotic/xonotic.git ${xonotic_directory}
cd ${xonotic_directory}
./all update -l best
./all checkout Juhu/battle-royale
./all compile -r dedicated

mkdir -p ${systemuserhome}/xonotic-br/data
chown -R ${systemuser}: ${systemuserhome}/xonotic-br

cat > ${systemuserhome}/xonotic-br/data/server.cfg <<EOF
sv_public 0
hostname "onFOSS"
maxplayers 64
port 26000
log_file "server.log"
g_start_delay 15
g_maplist "implosion glowplant dance geoplanetary xoylent"
g_maplist_shuffle 1
gametype br
rcon_password "onFOSS"
bot_number 4
skill 8
minplayers 4
bot_prefix [BOT]
g_maplist_votable 6
sv_weaponstats_file http://www.xonotic.org/weaponbalance/
EOF

cat > /etc/systemd/system/xonotic-br.service <<EOF
[Unit]
Description=Xonotic Battle Royale server
After=network.target
Conflicts=xonotic.service

[Service]
WorkingDirectory=${xonotic_directory}
ExecStart=/usr/bin/console2web -p 62550 ${xonotic_directory}/all run dedicated +serverconfig server.cfg -userdir ${systemuserhome}/xonotic-br
Restart=on-failure
User=${systemuser}

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
#systemctl enable --now xonotic-br.service

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
