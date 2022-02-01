#!/bin/bash
set -e

# OpenSpades
mkdir -p /opt/openspades
virtualenv -p python3 /opt/openspades/env
source /opt/openspades/env/bin/activate
pip install piqueserver
sudo -u ${systemuser} /opt/openspades/env/bin/piqueserver --copy-config
sudo -u ${systemuser} sed -i ${systemuserhome}/.config/piqueserver/config.toml -e s/"piqueserver instance"/"onFOSS"/
deactivate

cat > /etc/systemd/system/openspades.service <<EOF
[Unit]
Description=OpenSpades server
After=network.target

[Service]
ExecStart=/opt/openspades/env/bin/piqueserver
Restart=on-failure
User=${systemuser}

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now openspades.service

firewall-cmd --zone=public --add-port=32886/tcp --permanent
firewall-cmd --zone=public --add-port=32887/udp --permanent
