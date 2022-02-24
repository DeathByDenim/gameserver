#!/bin/sh

echo "Installing SuperTuxKart ${stk_version}"
exit

if [ -e /etc/systemd/system/supertuxkart.service ]; then
  systemctl stop supertuxkart
fi

# Install SuperTuxKart
stk_dir="/opt/SuperTuxKart-${stk_version}"
mkdir -p ${stk_dir}
curl --location "https://github.com/supertuxkart/stk-code/releases/download/${stk_version}/SuperTuxKart-${stk_version}-linux-64bit.tar.xz" | tar --extract --xz --no-same-owner --strip-components=1 --directory=${stk_dir}
ln -s ${stk_dir}/bin/supertuxkart /usr/games/supertuxkart

# Add firewall rules
firewall-cmd --zone=public --add-port=2757/udp --permanent
firewall-cmd --zone=public --add-port=2759/udp --permanent

# Configuration
cp $(dirname $0)/../config/supertuxkart.xml /etc/supertuxkart.xml

# Create SystemD unit
cat > /etc/systemd/system/supertuxkart.service <<EOF
[Unit]
Description=SuperTuxKart server
After=network.target

[Service]
ExecStart=${stk_dir}/run_game.sh --server-config=/etc/supertuxkart.xml --lan-server=onFOSS
Restart=on-failure
User=${systemuser}

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now supertuxkart.service

firewall-cmd --zone=public --add-port=2759/udp --permanent
firewall-cmd --zone=public --add-port=2757/udp --permanent
