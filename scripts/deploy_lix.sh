#!/bin/bash
set -e

if [ -e /etc/systemd/system/lix.service ]; then
  systemctl stop lix
fi

if [ -z ${lix_version} ] || [ "${lix_version}" = "latest" ]; then
  lix_version=$(curl -s https://api.github.com/repos/SimonN/LixD/releases/latest | jq -r '.["tag_name"]' | cut -c2-)
fi

# Install Lix
mkdir -p ${TMPDIR:-/tmp}/lix-build
cd ${TMPDIR:-/tmp}/lix-build
if [ -d LixD ]; then
  rm -rf LixD
fi
git clone --branch v${lix_version} https://github.com/SimonN/LixD.git
cd LixD/src/server
dub build
mkdir -p /opt/lix-${lix_version}
cp ../../bin/server /opt/lix-${lix_version}
rm -rf ${TMPDIR:-/tmp}/lix-build

# Create SystemD unit
cat > /etc/systemd/system/lix.service <<EOF
[Unit]
Description=Lix server
After=network.target

[Service]
ExecStart=/opt/lix-${lix_version}/server
Restart=on-failure
User=${systemuser}

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now lix.service

# Add firewall rules
firewall-cmd --zone=public --add-port=22934/udp --permanent
