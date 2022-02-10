#!/bin/bash
set -e

if [ -e /etc/systemd/system/openspades.service ]; then
  systemctl stop openspades
fi

# OpenSpades
mkdir -p /opt/openspades
if [ -d /opt/openspades/env ]; then
  rm -rf /opt/openspades/env
fi
virtualenv -p python3 /opt/openspades/env
source /opt/openspades/env/bin/activate
pip install -U piqueserver
pip install "twisted<21.0.0" # Twisted 22 removed getPage that piqueserver depends on for 1.0.0
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
