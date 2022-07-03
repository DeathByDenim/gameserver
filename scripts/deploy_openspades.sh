#!/bin/bash
set -e

if [ -e /etc/systemd/system/openspades.service ]; then
  systemctl stop openspades
fi

# Smallish maps from https://github.com/kinvaris/openspades-maps
## island
## nuketown (broken)
## pinpoint
## Realistic Bridge
## Rocket Island
## Submarine

# OpenSpades
mkdir -p /opt/openspades
if [ -d /opt/openspades/env ]; then
  rm -rf /opt/openspades/env
fi
virtualenv -p python3 /opt/openspades/env
source /opt/openspades/env/bin/activate
pip install -U piqueserver
pip install "twisted<21.0.0" # Twisted 22 removed getPage that piqueserver 1.0.0 depends on
pip install "MarkupSafe==2.0.1" # MarkupSafe removed soft_unicode that piqueserver 1.0.0 depends on
sudo -u ${systemuser} /opt/openspades/env/bin/piqueserver --copy-config
sudo -u ${systemuser} sed -i ${systemuserhome}/.config/piqueserver/config.toml \
  -e s/"piqueserver instance"/"onFOSS"/ \
  -e s/"#admin = \[\"adminpass1\", \"adminpass2\"\]"/"admin = \[\"${systempassword}\"\]"/ \
  -e s/"name = \"Blue\""/"name = \"Cyanide\""/ \
  -e s/"color = \[ 0, 0, 255\]"/"color = [ 0, 255, 255]"/ \
  -e s/"name = \"Green\""/"name = \"Pinkster\""/ \
  -e s/"color = \[ 0, 255, 0\]"/"color = [ 255, 0, 255]"/ \
  -e s/"  \"classicgen\","/"  \"island\",\n  \"pinpoint\",\n  \"realisticbridge\",\n  \"rocketisland\",\n  \"submarine\","/ \
  -e s/"default_time_limit = \"2hours\""/"default_time_limit = \"20minutes\""/
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

for map in island pinpoint realisticbridge rocketisland submarine; do
  curl "https://raw.githubusercontent.com/kinvaris/openspades-maps/master/${map}.txt" > ${systemuserhome}/.config/piqueserver/maps/${map}.txt
  curl "https://raw.githubusercontent.com/kinvaris/openspades-maps/master/${map}.vxl" > ${systemuserhome}/.config/piqueserver/maps/${map}.vxl
done

systemctl daemon-reload
systemctl enable --now openspades.service

firewall-cmd --zone=public --add-port=32886/tcp --permanent
firewall-cmd --zone=public --add-port=32887/udp --permanent
