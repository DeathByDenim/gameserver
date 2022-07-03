#!/bin/bash
set -e

if [ -e /etc/systemd/system/teeworlds-ddrace.service ]; then
  systemctl stop teeworlds
fi

# Teeworlds
teeworldsddrace_directory="/opt/teeworlds-ddrace-${teeworldsddrace_version}"
mkdir -p "${teeworldsddrace_directory}"
curl --location "https://ddnet.tw/downloads/DDNet-${teeworldsddrace_version}-linux_x86_64.tar.xz" | tar --extract --xz --no-same-owner --strip-components=1 --directory="${teeworldsddrace_directory}"
curl --location "https://maps.ddnet.tw/compilations/novice.zip" > ${TMPDIR:/tmp}/novice.zip
unzip -o -d "${teeworldsddrace_directory}"/data/maps ${TMPDIR:/tmp}/novice.zip
for f in "${teeworldsddrace_directory}"/data/maps/novice/maps/*.map; do
  "${teeworldsddrace_directory}"/map_convert_07 "$f" "`echo "$f" | sed s/"maps\/novice\/maps"/"maps7"/g`"
  cp "$f" "${teeworldsddrace_directory}"/data/maps
done
rm -rf "${teeworldsddrace_directory}"/data/maps/novice

cat > "${teeworldsddrace_directory}"/data/myServerconfig.cfg <<EOF
sv_name onFOSS
sv_map "Multeasymap"
sv_maprotation "4Beginners","4Nubs","Multeasymap"
sv_register 0
sv_rcon_password ${systempassword}
sv_sqlite_file "${systemuserhome}/.local/share/ddnet/ddnet-server.sqlite"
EOF

cat > /etc/systemd/system/teeworlds-ddrace.service <<EOF
[Unit]
Description=Teeworlds DDrace server
After=network.target
Conflicts=teeworlds.service

[Service]
ExecStart=${teeworldsddrace_directory}/DDNet-Server
Restart=on-failure
User=${systemuser}
WorkingDirectory=${teeworldsddrace_directory}

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

firewall-cmd --zone=public --add-port=8303/udp --permanent
