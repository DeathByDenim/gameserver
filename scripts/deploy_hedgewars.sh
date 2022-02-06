#!/bin/bash
set -e

if [ -e /etc/systemd/system/hedgewars.service ]; then
  systemctl stop hedgewars
fi

# Hedgewars
# Create SystemD unit
cat > /etc/systemd/system/hedgewars.service <<EOF
[Unit]
Description=Hedgewars server
After=network.target

[Service]
ExecStart=/usr/lib/hedgewars/bin/hedgewars-server
Restart=on-failure
User=${systemuser}

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now hedgewars.service

# Add firewall rules
firewall-cmd --zone=public --add-port=46631/tcp --permanent
