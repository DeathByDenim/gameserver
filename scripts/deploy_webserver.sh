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
  ssl="true"
  certbot -n --nginx -d ${DOMAINNAME} -d www.${DOMAINNAME} --agree-tos -m "${letsencryptemail}"
else
  ssl="false"
fi

# Generate the website and put in place
curl --location https://github.com/twbs/bootstrap/archive/v5.2.3.zip > ${TMPDIR:-/tmp}/bootstrap.zip
unzip -o -d ${TMPDIR:-/tmp}/bootstrap ${TMPDIR:-/tmp}/bootstrap.zip "bootstrap-5.2.3/scss/*"
if [ -d "$(dirname "$0")"/../website/_sass/bootstrap ]; then
  rm -r "$(dirname "$0")"/../website/_sass/bootstrap
fi
mv ${TMPDIR:-/tmp}/bootstrap/bootstrap-5.2.3/scss "$(dirname "$0")"/../website/_sass/bootstrap
rm -r ${TMPDIR:-/tmp}/bootstrap.zip ${TMPDIR:-/tmp}/bootstrap
cat > "$(dirname "$0")"/../website/_config.yml <<EOF
content:
  hosted_by_name: "${HOSTEDBYNAME}"
  domain_name: "${DOMAINNAME}"
  offline: false
  ssl: ${ssl}
  md5password: "$(echo -n "${systempassword}" | md5sum | cut -d' ' -f1)"
EOF
jekyll build --source "$(dirname "$0")"/../website --destination /var/www/html

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
