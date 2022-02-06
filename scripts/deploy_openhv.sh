#!/bin/bash
set -e

if [ -e /etc/systemd/system/openhv.service ]; then
  systemctl stop openhv
fi

# Install OpenHV
mkdir -p /opt/openhv-${openhv_version}
curl --location "https://github.com/OpenHV/OpenHV/releases/download/${openhv_version}/OpenHV-${openhv_version}-x86_64.AppImage" > /opt/openhv-${openhv_version}/OpenHV-x86_64.AppImage
chmod +x /opt/openhv-${openhv_version}/OpenHV-x86_64.AppImage

cat > /etc/systemd/system/openhv.service <<EOF
[Unit]
Description=OpenHV server
After=network.target

[Service]
ExecStart=/opt/openhv-${openhv_version}/OpenHV-x86_64.AppImage --server Server.Name="OnFOSS" Server.ListenPort=1234 Server.AdvertiseOnline=False
Restart=on-failure
User=${systemuser}

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now openhv.service

# Add firewall rules
firewall-cmd --zone=public --add-port=1234/tcp --permanent
