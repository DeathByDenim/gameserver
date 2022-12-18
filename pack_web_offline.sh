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

if ! which jekyll > /dev/null; then
  echo "Jekyll is required to generate the website"
  exit 1
fi

webroot=${TMPDIR:-/tmp}/website
mkdir -p ${webroot}
cp -r "$(dirname "$0")"/website/* ${webroot}

curl --location https://github.com/twbs/bootstrap/archive/v5.2.3.zip > ${TMPDIR:-/tmp}/bootstrap.zip
unzip -o -d ${TMPDIR:-/tmp}/bootstrap ${TMPDIR:-/tmp}/bootstrap.zip "bootstrap-5.2.3/scss/*"
if [ -d "$(dirname "$0")"/../website/_sass/bootstrap ]; then
  rm -r "$(dirname "$0")"/../website/_sass/bootstrap
fi
mv ${TMPDIR:-/tmp}/bootstrap/bootstrap-5.2.3/scss ${webroot}/_sass/bootstrap
rm -r ${TMPDIR:-/tmp}/bootstrap.zip ${TMPDIR:-/tmp}/bootstrap
cat > ${webroot}/_config.yml <<EOF
content:
  hosted_by_name: "${HOSTEDBYNAME}"
  domain_name: "${DOMAINNAME}"
  offline: true
  ssl: true
  md5password: "$(echo -n "${systempassword}" | md5sum | cut -d' ' -f1)"
EOF
jekyll build --source ${webroot} --destination ${webroot}/_site
tar -cjf web.tar.bz2 --directory="${webroot}/_site" .
rm -rf "${webroot}"
