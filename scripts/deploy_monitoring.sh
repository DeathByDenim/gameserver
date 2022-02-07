#!/bin/bash

git clone https://github.com/DeathByDenim/d3-serverstats.git
cd d3-serverstats
cp serverstats.py /usr/bin/

cat > /etc/systemd/system/serverstats.service <<EOF
[Unit]
Description=Server monitoring
After=network.target

[Service]
ExecStart=/usr/bin/serverstats.py
Restart=on-failure
User=${systemuser}

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now serverstats
