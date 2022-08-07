#!/bin/bash
set -e

if [ -e /etc/systemd/system/unvanquished.service ]; then
  systemctl stop unvanquished
fi

unvanquished_url="https://github.com/Unvanquished/Unvanquished/releases/download/v${unvanquished_version}/unvanquished_${unvanquished_version}.zip"
if [ -z ${unvanquished_version} ] || [ "${unvanquished_version}" = "latest" ]; then
  unvanquished_version=$(curl -s https://api.github.com/repos/Unvanquished/Unvanquished/releases/latest | jq -r '.["tag_name"]' | cut -c2-)
  unvanquished_url=$(curl -s https://api.github.com/repos/Unvanquished/Unvanquished/releases/latest | jq -r '.assets | .[] |  select(.size > 1000) | .browser_download_url')
fi

# Unvanquished
unvanquished_directory="/opt/unvanquished-${unvanquished_version}"
curl --location ${unvanquished_url} > ${TMPDIR:-/tmp}/unvanquished.zip
unzip -o -d ${TMPDIR:-/tmp} ${TMPDIR:-/tmp}/unvanquished.zip
mkdir -p ${unvanquished_directory}/bin ${unvanquished_directory}/share
unzip -o -d ${unvanquished_directory}/bin ${TMPDIR:-/tmp}/unvanquished*/linux-amd64.zip
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
set g_motd "^2get news on ^5${DOMAINNAME}"
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

cat > /etc/nginx/gameserver.d/unvanquished.conf <<EOF
location /unvanquished {
    proxy_pass http://localhost:62549/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "Upgrade";
    proxy_set_header Host \$host;
}
EOF

firewall-cmd --zone=public --add-port=27960/udp --permanent
