#!/bin/bash

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
for file in ${webroot}/*\.html; do
  sed -i $file -e "/SERVERSTATE/r $(dirname "$0")/website/_state/online.html"
  sed -i $file -e "/SERVERSTATE/d"
done
if [ $NOSSL -eq 1 ]; then
  for file in /var/www/html/js/*\.js; do
    sed -i $file -e s/"wss:"/"ws:"/g
  done
fi

# Patch the NGINX configuration for the web sockets
cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak
patch --ignore-whitespace /etc/nginx/sites-available/default <<EOF
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
@@ -121,6 +126,17 @@
                try_files \$uri \$uri/ =404;
        }

+        location ^~ /admin {
+                auth_basic "Restricted";
+                auth_basic_user_file /etc/nginx/htpasswd;
+        }
+
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
