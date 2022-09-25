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

if [ -e /etc/systemd/system/opensoldat.service ]; then
  systemctl stop opensoldat
fi

# Install dependencies
sudo apt-get -y install build-essential g++ cmake git fpc libprotobuf-dev protobuf-compiler libssl-dev libsdl2-dev libopenal-dev libphysfs-dev libfreetype6

# Install BZFlag
builddir=${TMPDIR:-/tmp}/opensoldat-build
mkdir -p ${builddir}
cd ${builddir}
if [ -d opensoldat ]; then
  rm -rf opensoldat
fi
git clone https://github.com/opensoldat/opensoldat.git
git clone https://github.com/opensoldat/base.git
cd opensoldat
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=/opt/opensoldat -DBUILD_CLIENT=False ..
make
make install
mkdir -p /opt/opensoldat/bin/configs /opt/opensoldat/bin/logs
cp -r ${builddir}/base/server/configs/bots /opt/opensoldat/bin/configs/bots

if ! [ -L /usr/games/opensoldatserver ]; then
  ln -s /opt/opensoldat/bin/opensoldatserver /usr/games/
fi

rm -rf ${builddir}

cat > /opt/opensoldat/bin/configs/server_dm.cfg <<EOF
sv_hostname "onFOSS LAN"
bots_random_alpha 0
sv_gamemode 0
sv_greeting "Welcome to the onFOSS LAN server"
sv_website ${DOMAINNAME}
bots_chat false
EOF

cat > /opt/opensoldat/bin/configs/server_ctf.cfg <<EOF
sv_hostname "onFOSS LAN"
bots_random_alpha 0
sv_gamemode 3
sv_greeting "Welcome to the onFOSS LAN server"
sv_website ${DOMAINNAME}
bots_chat false
sv_maplist "mapslist_ctf.txt"
EOF

if ! [ -L /opt/opensoldat/bin/configs/server.cfg ]; then
  ln -s ./server_dm.cfg /opt/opensoldat/bin/configs/server.cfg
fi

cat > /opt/opensoldat/bin/configs/mapslist.txt <<EOF
Aero
Airpirates
Arena2
Arena3
Arena
Bigfalls
Blox
Bridge
Bunker
Cambodia
CrackedBoot
Daybreak
DesertWind
Factory
Flashback
HH
Island2k5
Jungle
Krab
Lagrange
Leaf
MrSnowman
RatCave
Rok
RR
Shau
Tropiccave
Unlim
Veoto
EOF

cat > /opt/opensoldat/bin/configs/mapslist_ctf.txt <<EOF
ctf_Aftermath
ctf_Amnesia
ctf_Ash
ctf_B2b
ctf_Blade
ctf_Campeche
ctf_Cobra
ctf_Crucifix
ctf_Death
ctf_Division
ctf_Dropdown
ctf_Equinox
ctf_Guardian
ctf_Hormone
ctf_IceBeam
ctf_Kampf
ctf_Lanubya
ctf_Laos
ctf_Mayapan
ctf_Maya
ctf_MFM
ctf_Nuubia
ctf_Raspberry
ctf_Rotten
ctf_Ruins
ctf_Run
ctf_Scorpion
ctf_Snakebite
ctf_Steel
ctf_Triumph
ctf_Viet
ctf_Voland
ctf_Wretch
ctf_X
EOF

cat > /opt/opensoldat/bin/configs/mapslist_htf.txt <<EOF
htf_Arch
htf_Baire
htf_Boxed
htf_Desert
htf_Dorothy
htf_Dusk
htf_Erbium
htf_Feast
htf_Mossy
htf_Muygen
htf_Niall
htf_Nuclear
htf_Prison
htf_Rubik
htf_Star
htf_Tower
htf_Void
htf_Vortex
htf_Zajacz
EOF

cat > /opt/opensoldat/bin/configs/mapslist_inf.txt <<EOF
inf_Abel
inf_April
inf_Argy
inf_Belltower
inf_Biologic
inf_Changeling
inf_Flute
inf_Fortress
inf_Industrial
inf_Messner
inf_Moonshine
inf_Motheaten
inf_Outpost
inf_Rescue
inf_Rise
inf_Warehouse
inf_Warlock
EOF

chown -R ${systemuser}: /opt/opensoldat/bin/configs /opt/opensoldat/bin/logs

# Create SystemD unit
cat > /etc/systemd/system/opensoldat.service <<EOF
[Unit]
Description=Soldat server
After=network.target
Requires=opensoldat-monitor.service

[Service]
ExecStart=/usr/games/opensoldatserver -sv_adminpassword "${systempassword}"
Restart=on-failure
User=${systemuser}

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/opensoldat-monitor.service <<EOF
[Unit]
Description=Soldat server monitor
After=network.target,opensoldat.service
Requires=opensoldat.service

[Service]
ExecStartPre=/bin/sh -c 'sleep 10'
ExecStart=/usr/bin/console2web -a "${systempassword}" -p 62554 -b "${systempassword}" telnet localhost 23073
Restart=on-failure
User=${systemuser}

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now opensoldat.service opensoldat-monitor.service

cat > /etc/nginx/gameserver.d/opensoldat.conf <<EOF
location /opensoldat {
    proxy_pass http://localhost:62554/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "Upgrade";
    proxy_set_header Host \$host;
}
EOF

# Add firewall rules
firewall-cmd --zone=public --add-port=23073/udp --permanent
firewall-cmd --zone=public --add-port=23083/tcp --permanent
