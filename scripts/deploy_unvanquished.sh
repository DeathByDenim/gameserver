#!/bin/bash
set -e

if [ -e /etc/systemd/system/unvanquished.service ]; then
  systemctl stop unvanquished
fi

# Unvanquished
unvanquished_directory="/opt/unvanquished-${unvanquished_version}"
curl --location "https://github.com/Unvanquished/Unvanquished/releases/download/v${unvanquished_version}/unvanquished_${unvanquished_version}.zip" > ${TMPDIR:-/tmp}/unvanquished.zip
unzip -o -f -d ${TMPDIR:-/tmp} ${TMPDIR:-/tmp}/unvanquished.zip
mkdir -p ${unvanquished_directory}/bin ${unvanquished_directory}/share
unzip -o -f -d ${unvanquished_directory}/bin ${TMPDIR:-/tmp}/unvanquished*/linux-amd64.zip
if [ -d ${unvanquished_directory}/share/pkg ]; then
  rm -rf ${unvanquished_directory}/share/pkg
fi
mv ${TMPDIR:-/tmp}/unvanquished*/pkg ${unvanquished_directory}/share
rm -rf ${TMPDIR:-/tmp}/unvanquished*

mkdir -p ${systemuserhome}/unvanquished_home/config
cat > ${systemuserhome}/unvanquished_home/config/unvanquished.cfg <<EOF
set server.private 1
set g_needpass 0
set sv_hostname "^NUnvanquished ^3onFOSS-LAN"
set g_motd "^2get news on ^5${LINODE_ID}"
set sv_allowdownload 0
set sv_maxclients 24
set timelimit 0
set g_emptyTeamsSkipMapTime 15
set g_teamForceBalance 1
set g_mapConfigs "map"
set g_initialMapRotation rotation1
map yocto
EOF
chown -R ${systemuser}: ${systemuserhome}/unvanquished_home

cat > /etc/systemd/system/unvanquished.service <<EOF
[Unit]
Description=Unvanquished server
After=network.target

[Service]
ExecStart=/usr/bin/console2web -p 62549 ${unvanquished_directory}/bin/daemonded -pakpath ${unvanquished_directory}/share/pkg/ -libpath ${unvanquished_directory}/bin/ -homepath \${HOME}/unvanquished_home/ +exec unvanquished.cfg
Restart=on-failure
User=${systemuser}

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now unvanquished.service

firewall-cmd --zone=public --add-port=27960/udp --permanent