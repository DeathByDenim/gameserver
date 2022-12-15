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

if [ -e /lib/systemd/system/armagetronad-dedicated.service ]; then
  systemctl stop armagetronad-dedicated
fi

apt install --assume-yes armagetronad-dedicated

# Override unit file to use console2web
mkdir -p /etc/systemd/system/armagetronad-dedicated.service.d
cat > /etc/systemd/system/armagetronad-dedicated.service.d/override.conf <<EOF
[Service]
ExecStart=
ExecStart=/usr/bin/console2web -a "${systempassword}" -p 62551 /usr/games/armagetronad-dedicated.real --datadir /usr/share/games/armagetronad --configdir /etc/armagetronad --userdatadir /var/games/armagetronad
EOF
systemctl daemon-reload

cat > /etc/armagetronad/server_info.cfg <<EOF
MESSAGE_OF_DAY Welcome to onFOSS-LAN\\nTry to survive as long as possible!\\nNote that you can brake by pressing the down arrow key\\nHugging walls will give you a speed boost\\n\\nPress <Enter> to start!
SERVER_NAME onFOSS-LAN
EOF

cat > /etc/armagetronad/settings_custom.cfg <<EOF
TALK_TO_MASTER 0
EOF

systemctl restart armagetronad-dedicated.service

cat > /etc/nginx/gameserver.d/armagetron.conf <<EOF
location /armagetron {
    proxy_pass http://localhost:62551/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "Upgrade";
    proxy_set_header Host \$host;
}
EOF

# Add firewall rules
firewall-cmd --zone=public --add-port=4534/udp --permanent
