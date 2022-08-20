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

# Web dashboard
systemctl enable --now nginx

firewall-cmd --zone=public --add-service=http --permanent
firewall-cmd --zone=public --add-service=https --permanent
firewall-cmd --reload

# Request SSL certificate. This assumes DNS has been set up already
if [ x"$NOSSL" = "x" ] || [ $NOSSL -ne 1 ]; then
  certbot -n --nginx -d ${DOMAINNAME} -d www.${DOMAINNAME} --agree-tos -m "${letsencryptemail}"
fi

# Put the website files in place
cp -r "$(dirname "$0")"/../website/[^_]* /var/www/html
for file in /var/www/html/*\.html /var/www/html/js/*\.js; do
  sed -i $file -e s/"DOMAINNAME"/"${DOMAINNAME}"/g
done
for file in /var/www/html/*\.html; do
  sed -i $file -e s/"HOSTEDBYNAME"/"${HOSTEDBYNAME}"/g
done
for file in /var/www/html/*\.html; do
  sed -i $file -e "/SERVERSTATE/r $(dirname "$0")/../website/_state/online.html"
  sed -i $file -e "/SERVERSTATE/d"
done
if [ x"$NOSSL" != "x" ] && [ $NOSSL -eq 1 ]; then
  for file in /var/www/html/js/*\.js; do
    sed -i $file -e s/"wss:"/"ws:"/g
    sed -i $file -e s/"https:"/"http:"/g
  done
fi
sed -i /var/www/html/js/consoles.js -e s/"MD5GAMEPASSWORD"/"$(echo -n "${systempassword}" | md5sum | cut -d' ' -f1)"/g

# Patch the NGINX configuration for the web sockets
cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak
patch --ignore-whitespace --force /etc/nginx/sites-available/default <<EOF
--- default.bak 2022-02-09 12:00:07.665387879 +0000
+++ default     2022-02-09 12:02:41.083719671 +0000
@@ -16,6 +16,11 @@
 # Please see /usr/share/doc/nginx-doc/examples/ for more detailed examples.
 ##

+map \$http_upgrade \$connection_upgrade {
+        default upgrade;
+        '' close;
+}
+
 # Default server configuration
 #
 server {
@@ -121,6 +126,20 @@
                try_files \$uri \$uri/ =404;
        }

+        location ^~ /admin {
+                auth_basic "Restricted";
+                auth_basic_user_file /etc/nginx/htpasswd;
+        }
+
+        proxy_connect_timeout 1d;
+        proxy_send_timeout 1d;
+        proxy_read_timeout 1d;
+        include /etc/nginx/gameserver.d/*.conf;
+
+        location /monitoring/ {
+            proxy_pass http://localhost:9000/;
+        }
+
        # pass PHP scripts to FastCGI server
        #
        #location ~ \\.php\$ {
EOF

mkdir -p /etc/nginx/gameserver.d

# Store password
echo -n "${systemuser}:" > /etc/nginx/htpasswd
echo -e "import bcrypt\nprint(bcrypt.hashpw('${systempassword}'.encode('utf8'),bcrypt.gensalt(rounds=10)).decode('utf8'))" | python3 >> /etc/nginx/htpasswd

systemctl restart nginx
