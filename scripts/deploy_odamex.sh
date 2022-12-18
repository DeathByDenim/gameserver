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

if [ -e /etc/systemd/system/odamex.service ]; then
  systemctl stop odamex
fi

if [ -z ${odamex_version} ] || [ "${odamex_version}" = "latest" ]; then
  odamex_version=$(curl -s https://api.github.com/repos/odamex/odamex/releases/latest | jq -r '.["tag_name"]')
fi

# Install ODAMEX
apt install --assume-yes libsdl2-dev libsdl2-mixer-dev cmake deutex freedoom libpng-dev
mkdir -p ${TMPDIR:-/tmp}/odamex-build
curl --location https://github.com/odamex/odamex/releases/download/${odamex_version}/odamex-src-${odamex_version}.tar.gz | tar --extract --gz --no-same-owner --directory="${TMPDIR:-/tmp}/odamex-build"
mkdir ${TMPDIR:-/tmp}/odamex-build/odamex-src-${odamex_version}/build
cd ${TMPDIR:-/tmp}/odamex-build/odamex-src-${odamex_version}/build
cmake -DBUILD_CLIENT=OFF -DBUILD_SERVER=ON -DBUILD_LAUNCHER=OFF -DCMAKE_INSTALL_PREFIX=/opt/odamex-${odamex_version} ..
make
make install

# Build AppImage
mkdir -p AppDir
cmake -DBUILD_CLIENT=ON -DBUILD_SERVER=OFF -DBUILD_LAUNCHER=OFF -DCMAKE_INSTALL_PREFIX=AppDir ..
make
make install
curl -O --location 'https://github.com/linuxdeploy/linuxdeploy-plugin-appimage/releases/download/continuous/linuxdeploy-plugin-appimage-x86_64.AppImage'
curl -O --location 'https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage'
chmod +x linuxdeploy-plugin-appimage-x86_64.AppImage linuxdeploy-x86_64.AppImage
mkdir -p AppDir/usr/share/applications
cat > AppDir/usr/share/applications/odamex.desktop <<EOF
[Desktop Entry]
Type=Application
Categories=Game
Name=Odamex
Exec=odamex
Icon=odamex
StartupNotify=false
Terminal=false
EOF
for f in ../media/icon_odamex_*.png; do
  resolution=$(echo $f | sed s/"..\/media\/icon_odamex_\([0-9]*\).png"/\\1/g)
  mkdir -p AppDir/usr/share/icons/hicolor/${resolution}x${resolution}/apps/
  cp $f AppDir/usr/share/icons/hicolor/${resolution}x${resolution}/apps/odamex.png
done
cat > AppDir/AppRun <<EOF
#!/bin/bash
export DOOMWADPATH=\$APPDIR/share/odamex/
\$APPDIR/bin/odamex \$@
EOF
chmod +x AppDir/AppRun
./linuxdeploy-x86_64.AppImage --appdir AppDir --output=appimage
cp Odamex-x86_64.AppImage /var/www/html/assets
cd -
rm -rf ${TMPDIR:-/tmp}/odamex-build

proto="http"
if [ x"$NOSSL" = "x" ] || [ $NOSSL -ne 1 ]; then
  proto="https"
fi

mkdir -p /home/${systemuser}/.odamex/
cat > /home/${systemuser}/.odamex/odasrv.cfg <<EOF
set sv_hostname "OnFOSS LAN"
set sv_motd "Welcome to OnFOSS LAN DOOM server"
set sv_website "${proto}://${DOMAINNAME}/"
set sv_downloadsites "${proto}://${DOMAINNAME}/wads/"
set rcon_password "${systempassword}"
set sv_gametype "0"
set sv_skill "3"
set sv_maxplayers "32"
set sv_monstersrespawn 120
set sv_warmup 1
set sv_countdown 5
EOF
chown -R ${systemuser}: /home/${systemuser}/.odamex/

# Create SystemD unit
cat > /etc/systemd/system/odamex.service <<EOF
[Unit]
Description=ODAMEX server
After=network.target

[Service]
ExecStart=/opt/odamex-${odamex_version}/bin/odasrv
Restart=on-failure
User=${systemuser}

[Install]
WantedBy=multi-user.target
EOF

# Make wads available for download
mkdir -p /var/www/html/wads
cp -r /usr/share/games/doom/freedoom?.wad /var/www/html/wads

systemctl daemon-reload
systemctl enable --now odamex.service

# Add firewall rules
firewall-cmd --zone=public --add-port=10666/udp --permanent
