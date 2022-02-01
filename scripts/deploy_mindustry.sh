#!/bin/bash
set -e

# Mindustry
mkdir -p /opt/mindustry-v${mindustry_version}
curl --location https://github.com/Anuken/Mindustry/releases/download/v${mindustry_version}/server-release.jar > /opt/mindustry-v${mindustry_version}/mindustry.jar
mkdir -p /var/lib/mindustry
chown -R ${systemuser} /var/lib/mindustry

cat > /etc/systemd/system/mindustry.service <<EOF
[Unit]
Description=Mindustry server
After=network.target

[Service]
WorkingDirectory=/var/lib/mindustry
ExecStart=/usr/bin/console2web -p 62548 /usr/lib/jvm/java-11-openjdk-amd64/bin/java -jar /opt/mindustry-v${mindustry_version}/mindustry.jar
Restart=on-failure
User=${systemuser}

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now mindustry.service

firewall-cmd --zone=public --add-port=6567/tcp --permanent
firewall-cmd --zone=public --add-port=6567/udp --permanent
