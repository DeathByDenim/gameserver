#!/bin/bash
# Collection of scripts to deploy a server hosting several open-source games
# Copyright (C) 2022  Jarno van der Kolk
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

set -e

if [ -e /etc/systemd/system/teeworlds-ddrace.service ]; then
  systemctl stop teeworlds
fi

# Teeworlds
teeworldsddrace_directory="/opt/teeworlds-ddrace-${teeworldsddrace_version}"
mkdir -p "${teeworldsddrace_directory}"

# Download is unreliable at times. Retry a few times before failing
retry_count=3
while [ $retry_count -gt 0 ]; do
  curl --location "https://ddnet.tw/downloads/DDNet-${teeworldsddrace_version}-linux_x86_64.tar.xz" | tar --extract --xz --no-same-owner --strip-components=1 --directory="${teeworldsddrace_directory}"
  if [ $? -eq 0 ]; then
    break
  fi
  sleep 20
  (( retry_count-- ))
done
if [ $retry_count -le 0 ]; then
  exit 1
fi

retry_count=3
while [ $retry_count -gt 0 ]; do
  curl --location "https://maps.ddnet.tw/compilations/novice.zip" > ${TMPDIR:-/tmp}/novice.zip
  if [ $? -eq 0 ]; then 
    break
  fi
  sleep 20
  (( retry_count-- ))
done
if [ $retry_count -le 0 ]; then
  exit 1
fi

unzip -o -d "${teeworldsddrace_directory}"/data/maps ${TMPDIR:-/tmp}/novice.zip
for f in "${teeworldsddrace_directory}"/data/maps/novice/maps/*.map; do
  if "${teeworldsddrace_directory}"/map_convert_07 "$f" "`echo "$f" | sed s/"maps\/novice\/maps"/"maps7"/g`"; then
    cp "$f" "${teeworldsddrace_directory}"/data/maps
  fi
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
