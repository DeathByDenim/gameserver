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

if [ x"$NOSSL" = "x" ] || [ $NOSSL -ne 1 ]; then
  ssl="true"
  s_for_https="s"
else
  ssl="false"
  s_for_https=""
fi

cat > ${webroot}/_config.yml <<EOF
title: "onFOSS"
description: >
  onFOSS-LAN is a online, "Free (as Freedom) and Open Source" LAN-Party hosted by ${HOSTEDBYNAME} The goal is to get people together, enjoying the art of computer games and having a great time in these days. The FOSS community is a place of being open minded and acceptance to all different kinds of people with the focus of fully transparent systems and protecting individuals. So it does not matter if you are on Windows, Mac or Linux and it is also NOT necessary to have a PC MASTERRACE setup to run those games.
url: http${s_for_https}://${DOMAINNAME}

content:
  hosted_by_name: "${HOSTEDBYNAME}"
  domain_name: "${DOMAINNAME}"
  offline: true
  ssl: ${ssl}
  md5password: "$(echo -n "${systempassword}" | md5sum | cut -d' ' -f1)"

defaults:
  -
    scope:
      path: ""
      type: "posts"
    values:
      layout: "post"

plugins:
  - jekyll-feed
EOF
jekyll build --source ${webroot} --destination ${webroot}/_site
tar -cjf web.tar.bz2 --directory="${webroot}/_site" .
rm -rf "${webroot}"
