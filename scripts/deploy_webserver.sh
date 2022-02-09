#!/bin/bash

set -e

# Web dashboard
systemctl enable --now nginx

firewall-cmd --zone=public --add-service=http --permanent
firewall-cmd --zone=public --add-service=https --permanent
firewall-cmd --reload

# Request SSL certificate. This assumes DNS has been set up already
certbot -n --nginx -d ${DOMAINNAME} -d www.${DOMAINNAME} --agree-tos -m "${letsencryptemail}"

# Put the website files in place
cp -r "$(dirname "$0")"/../website/* /var/www/html
for file in $(grep -lR 192.168 /var/www/html/); do
  sed -i $file -e s/"192\.168\.122\.229"/"${DOMAINNAME}"/g
done
for file in $(grep -lR 192.168 /var/www/html/); do
  sed -i $file -e s/"ws:\/\/"/"wss:\/\/"/g
done

# Patch the NGINX configuration for the web sockets
cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak
patch /etc/nginx/sites-available/default <<EOF
--- default.bak 2022-02-06 21:02:32.827769618 +0000
+++ default     2022-02-06 21:02:32.827769618 +0000
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
@@ -121,6 +130,30 @@
                try_files \$uri \$uri/ =404;
        }

+        location /mindustry {
+            proxy_pass http://localhost:62548/;
+            proxy_http_version 1.1;
+            proxy_set_header Upgrade \$http_upgrade;
+            proxy_set_header Connection "Upgrade";
+            proxy_set_header Host \$host;
+        }
+
+        location /unvanquished {
+            proxy_pass http://localhost:62549/;
+            proxy_http_version 1.1;
+            proxy_set_header Upgrade \$http_upgrade;
+            proxy_set_header Connection "Upgrade";
+            proxy_set_header Host \$host;
+        }
+
+        location /xonotic {
+            proxy_pass http://localhost:62550/;
+            proxy_http_version 1.1;
+            proxy_set_header Upgrade \$http_upgrade;
+            proxy_set_header Connection "Upgrade";
+            proxy_set_header Host \$host;
+        }
+
+        location /monitoring/ {
+            proxy_pass http://localhost:9000/;
+        }
+
        # pass PHP scripts to FastCGI server
        #
        #location ~ \\.php\$ {
EOF

systemctl restart nginx
