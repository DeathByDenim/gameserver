#!/bin/bash
set -e

if [ -e /etc/systemd/system/supertuxparty.service ]; then
  systemctl stop supertuxparty
fi

# Install Lix
mkdir -p /opt/supertuxparty
curl 'https://supertux.party/download/latest/server.zip' > ${TMPDIR:/tmp}/server.zip
unzip -d /opt/supertuxparty ${TMPDIR:/tmp}/server.zip
rm ${TMPDIR:/tmp}/server.zip

# Create SystemD unit
cat > /etc/systemd/system/supertuxparty.service <<EOF
[Unit]
Description=Super Tux Party server
After=network.target

[Service]
WorkingDirectory=/opt/supertuxparty
ExecStart=/opt/supertuxparty/supertuxparty_server
Restart=on-failure
User=${systemuser}

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now supertuxparty.service

# Add firewall rules
firewall-cmd --zone=public --add-port=7634/udp --permanent
