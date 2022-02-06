#!/bin/bash
set -e

if [ -e /etc/systemd/system/bzflag.service ]; then
  systemctl stop bzflag
fi

# Install BZFlag
mkdir -p ${TMPDIR:-/tmp}/bzflag-build
cd ${TMPDIR:-/tmp}/bzflag-build
if [ -d bzflag ]; then
  rm -rf bzflag
fi
git clone --branch ${bzflag_version} https://github.com/BZFlag-Dev/bzflag.git
cd bzflag
./autogen.sh
./configure --disable-client --prefix=/opt/bzflag-${bzflag_version}
make
make install
if ! [ -L /usr/games/bzfs ]; then
  ln -s /opt/bzflag-2.4/bin/bzfs /usr/games/
fi

rm -rf ${TMPDIR:-/tmp}/bzflag-build

# Create SystemD unit
cat > /etc/systemd/system/bzflag.service <<EOF
[Unit]
Description=BZFlag server
After=network.target

[Service]
ExecStart=/usr/games/bzfs -ms 5 -j -t +r +f SW +f SB{2} +f GM +f ST{3} -d -d -d
Restart=on-failure
User=${systemuser}

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now bzflag.service

# Add firewall rules
firewall-cmd --zone=public --add-port=5154/tcp --permanent
firewall-cmd --zone=public --add-port=5154-5200/udp --permanent
