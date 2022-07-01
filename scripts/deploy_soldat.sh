#!/bin/bash
set -e

if [ -e /etc/systemd/system/soldat.service ]; then
  systemctl stop soldat
fi

# Install dependencies
sudo apt-get -y install build-essential g++ cmake git fpc libprotobuf-dev protobuf-compiler libssl-dev libsdl2-dev libopenal-dev libphysfs-dev libfreetype6

# Install BZFlag
builddir=${TMPDIR:-/tmp}/soldat-build
mkdir -p ${builddir}
cd ${builddir}
if [ -d soldat ]; then
  rm -rf soldat
fi
git clone https://github.com/Soldat/soldat.git
git clone https://github.com/Soldat/base.git
cd soldat
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=/opt/soldat ..
make
make install
mkdir -p /opt/soldat/bin/configs
cp -r ${builddir}/base/server/configs/bots /opt/soldat/bin/configs/bots

if ! [ -L /usr/games/soldatserver ]; then
  ln -s /opt/soldat/bin/soldatserver /usr/games/
fi

rm -rf ${builddir}

cat > /opt/soldat/bin/configs/server_dm.cfg <<EOF
sv_hostname "onFOSS LAN"
bots_random_alpha 0
sv_gamemode 0
sv_greeting "Welcome to the onFOSS LAN server"
sv_website ${DOMAINNAME}
bots_chat false
EOF

cat > /opt/soldat/bin/configs/server_ctf.cfg <<EOF
sv_hostname "onFOSS LAN"
bots_random_alpha 0
sv_gamemode 3
sv_greeting "Welcome to the onFOSS LAN server"
sv_website ${DOMAINNAME}
bots_chat false
sv_maplist "mapslist_ctf.txt"
EOF

ln -s ./server_dm.cfg /opt/soldat/bin/configs/server.cfg

cat > /opt/soldat/bin/configs/mapslist.txt <<EOF
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

cat > /opt/soldat/bin/configs/mapslist_ctf.txt <<EOF
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

cat > /opt/soldat/bin/configs/mapslist_htf.txt <<EOF
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

cat > /opt/soldat/bin/configs/mapslist_inf.txt <<EOF
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

chown -R ${systemuser}: /opt/soldat/bin/configs

# Create SystemD unit
cat > /etc/systemd/system/soldat.service <<EOF
[Unit]
Description=Soldat server
After=network.target

[Service]
ExecStart=/usr/games/soldatserver -sv_adminpassword "${systempassword}"
Restart=on-failure
User=${systemuser}

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now soldat.service

# Add firewall rules
firewall-cmd --zone=public --add-port=23073/udp --permanent
