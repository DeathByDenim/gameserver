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
  ln -s /opt/bzflag-${bzflag_version}/bin/bzfs /usr/games/
fi
if ! [ -L /usr/games/bzadmin ]; then
  ln -s /opt/bzflag-${bzflag_version}/bin/bzadmin /usr/games/
fi

rm -rf ${TMPDIR:-/tmp}/bzflag-build

# Create SystemD unit
cat > /etc/systemd/system/bzflag.service <<EOF
[Unit]
Description=BZFlag server
After=network.target
Requires=bzflag-monitor.service

[Service]
ExecStart=/usr/games/bzfs -ms 5 -j -t +r +f SW +f SB{2} +f GM +f ST{3} -d -d -d -passwd "${systempassword}"
Restart=on-failure
User=${systemuser}

[Install]
WantedBy=multi-user.target
EOF

# Create SystemD unit
cat > /etc/systemd/system/bzflag-monitor.service <<EOF
[Unit]
Description=BZFlag server monitor
After=bzflag.service
Requires=bzflag.service

[Service]
ExecStart=/usr/bin/console2web -p 62553 /usr/games/bzadmin admin@localhost -ui stdboth "/password ${systempassword}"
Restart=on-failure
User=${systemuser}

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now bzflag.service

cat > /etc/nginx/gameserver.d/bzflag.conf <<EOF
location /bzflag {
    proxy_pass http://localhost:62553/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "Upgrade";
    proxy_set_header Host \$host;
}
EOF

# Add firewall rules
firewall-cmd --zone=public --add-port=5154/tcp --permanent
firewall-cmd --zone=public --add-port=5154-5200/udp --permanent
