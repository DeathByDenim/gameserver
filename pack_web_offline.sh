#!/bin/bash

# Package a version of the website for offline use on a different web server.
# Used to indicate that the VM running the game servers is off.

set -e

webroot=${TMPDIR:-/tmp}/website
mkdir -p ${webroot}
cp -r "$(dirname "$0")"/website/[^_]* ${webroot}
for file in ${webroot}/*\.html ${webroot}/js/*\.js; do
  sed -i $file -e s/"DOMAINNAME"/"${DOMAINNAME}"/g
done
for file in ${webroot}/*\.html; do
  sed -i $file -e s/"HOSTEDBYNAME"/"${HOSTEDBYNAME}"/g
done
for file in ${webroot}/*\.html; do
  sed -i $file -e "/SERVERSTATE/r $(dirname "$0")/website/_state/offline.html"
  sed -i $file -e "/SERVERSTATE/d"
done
tar -cjf web.tar.bz2 --directory="${webroot}" .
rm -rf "${webroot}"
