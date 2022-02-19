#!/bin/bash
set -e

if [ -e /lib/systemd/system/armagetronad-dedicated.service ]; then
  systemctl stop armagetronad-dedicated
fi

apt install armagetronad-dedicated

# Override unit file to use console2web
cat > /etc/systemd/system/armagetronad-dedicated.service.d/override.conf <<EOF
[Service]
ExecStart=
ExecStart=/usr/bin/console2web -p 62551 /usr/games/armagetronad-dedicated.real --datadir /usr/share/games/armagetronad --configdir /etc/armagetronad --userdatadir /var/games/armagetronad
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

cat > /etc/nginx/gameserver.d/armagetronad.conf <<EOF
location /armagetronad {
    proxy_pass http://localhost:62551/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "Upgrade";
    proxy_set_header Host \$host;
}
EOF

# Add firewall rules
firewall-cmd --zone=public --add-port=4534/udp --permanent
