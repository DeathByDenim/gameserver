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

### Package a version of the website for offline use on a different web server.
### Used to indicate that the VM running the game servers is off.
### Specify domain name:
###   DOMAINNAME=example.com HOSTEDBYNAME=DeathByDenim ./pack_web_offline.sh

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
