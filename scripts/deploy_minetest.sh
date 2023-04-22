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

apt install --assume-yes libsqlite3-dev zlib1g-dev libgmp-dev libjsoncpp-dev libzstd-dev libluajit-5.1-dev cmake

if [ -e /etc/systemd/system/minetest.service ]; then
  systemctl stop minetest
fi

if [ -z ${minetest_version} ] || [ "${minetest_version}" = "latest" ]; then
  minetest_version=$(curl -s https://api.github.com/repos/minetest/minetest/releases/latest | jq -r '.["tag_name"]')
fi

# Install minetest
mkdir -p ${TMPDIR:-/tmp}/minetest-build
curl --location "https://github.com/minetest/minetest/archive/refs/tags/${minetest_version}.tar.gz" | tar --extract --gzip --no-same-owner --directory=${TMPDIR:-/tmp}/minetest-build
mkdir -p ${TMPDIR:-/tmp}/minetest-build/minetest-${minetest_version}/build
git clone --depth 1 https://github.com/minetest/minetest_game.git ${TMPDIR:-/tmp}/minetest-build/minetest-${minetest_version}/games/minetest_game
git clone --depth 1 --branch "1.9.0mt10" https://github.com/minetest/irrlicht.git ${TMPDIR:-/tmp}/minetest-build/minetest-${minetest_version}/lib/irrlichtmt
cd ${TMPDIR:-/tmp}/minetest-build/minetest-${minetest_version}/build
cmake -DCMAKE_INSTALL_PREFIX=/opt/minetest-${minetest_version} -DBUILD_CLIENT=FALSE -DBUILD_SERVER=TRUE ..
make
make install
cd -
rm -rf ${TMPDIR:-/tmp}/minetest-build

sudo -u ${systemuser} mkdir -p /home/${systemuser}/.minetest/games
curl --location https://content.minetest.net/packages/MisterE/blockbomber/releases/11576/download/ > ${TMPDIR:-/tmp}/blockbomber.zip
sudo -u ${systemuser} unzip -o -d /home/${systemuser}/.minetest/games "${TMPDIR:-/tmp}"/blockbomber.zip
rm -f "${TMPDIR:-/tmp}/blockbomber.zip"

cat > /etc/systemd/system/minetest.service <<EOF
[Unit]
Description=Minetest server
After=network.target

[Service]
ExecStart=/opt/minetest-${minetest_version}/bin/minetestserver --config /etc/minetest.conf --gameid blockbomber
Restart=on-failure
User=${systemuser}

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/minetest.conf <<EOF
server_name = onFOSS LAN server
server_address = ${DOMAINNAME}
server_announce = false
max_users = 32
enable_split_login_register = false
ipv6_server = true
EOF

systemctl daemon-reload
systemctl enable --now minetest.service

# Add firewall rules
firewall-cmd --zone=public --add-port=30000/udp --permanent
