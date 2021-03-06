#!/bin/bash

# Freeciv-web Travis CI Bootstrap Script - play.freeciv.org 
#
# https://travis-ci.org/freeciv/freeciv-web
#
# script is run to install Freeciv-web on Travis CI continuous integration.
echo "Installing Freeciv-web on Travis CI."
basedir=$(pwd)
logfile="${basedir}/freeciv-web-travis.log"


# Redirect copy of output to a log file.
exec > >(tee ${logfile})
exec 2>&1
set -e

echo "================================="
echo "Running Freeciv-web setup script."
echo "================================="

uname -a
echo basedir  $basedir
echo logfile $logfile

# User will need permissions to create a database
mysql_user="root"

resin_version="4.0.44"
resin_url="http://www.caucho.com/download/resin-${resin_version}.tar.gz"
tornado_url="https://pypi.python.org/packages/source/t/tornado/tornado-4.2.1.tar.gz"
nginx_url="http://nginx.org/download/nginx-1.9.6.tar.gz"

# Based on fresh install of Ubuntu 12.04
dependencies="maven mysql-server-5.5 openjdk-7-jdk libcurl4-openssl-dev subversion pngcrush libtool automake autoconf autotools-dev language-pack-en python3-setuptools python3.4 python3.4-dev imagemagick liblzma-dev firefox xvfb libicu-dev libsdl1.2-dev libjansson-dev"

## dependencies
echo "==== Installing Updates and Dependencies ===="
echo "apt-get update"
apt-get -y update
echo "apt-get install dependencies"
apt-get -y install ${dependencies}

ln -s /usr/bin/python3.4 /usr/bin/python3.5
python3.5 -m easy_install Pillow

java -version
javac -version

## build/install resin
echo "==== Fetching/Installing Resin ${resin_version} ===="
wget ${resin_url}
tar xfz resin-${resin_version}.tar.gz
rm -Rf resin
mv resin-${resin_version} resin
cd resin
./configure --prefix=`pwd`; make; make install
cd ..
chmod -R 777 resin


echo "==== Fetching/Installing Tornado Web Server ===="
wget ${tornado_url}
tar xfz tornado-4.2.1.tar.gz
cd tornado-4.2.1
python3.5 setup.py install

## mysql setup
echo "==== Setting up MySQL ===="
mysqladmin -u ${mysql_user}  create freeciv_web
mysql -u ${mysql_user}  freeciv_web < ${basedir}/freeciv-web/src/main/webapp/meta/private/metaserver.sql

sed -e "s/10/2/" ${basedir}/publite2/settings.ini.dist > ${basedir}/publite2/settings.ini

echo "==== Checking out Freeciv from SVN and patching... ===="
cd ${basedir}/freeciv && ./prepare_freeciv.sh
echo "==== Building freeciv ===="
cd freeciv && make install

echo "==== Building freeciv-web ===="
sed -e "s/user>root/user>${mysql_user}/" -e "s/password>changeme/password>/" ${basedir}/freeciv-web/src/main/webapp/WEB-INF/resin-web.xml.dist > ${basedir}/freeciv-web/src/main/webapp/WEB-INF/resin-web.xml
cd ${basedir}/scripts/freeciv-img-extract/ && ./setup_links.sh && ./sync.sh
cd ${basedir}/scripts && ./sync-js-hand.sh
cd ${basedir}/freeciv-web && sudo -u travis ./setup.sh

echo "==== Building nginx ===="
cd ${basedir}
wget ${nginx_url}
tar xzf nginx-1.9.6.tar.gz
cd nginx-1.9.6
./configure
make > nginx-log-file 2>&1
make install

cp ${basedir}/publite2/nginx.conf /usr/local/nginx/conf/
cp ${basedir}/pbem/settings.ini.dist ${basedir}/pbem/settings.ini

echo "Starting Freeciv-web..."
/usr/local/nginx/sbin/nginx
cd ${basedir}/scripts/ && sudo -u travis ./start-freeciv-web.sh

cat ${basedir}/logs/*.log 

echo "============================================"
echo "Installing CasperJS for testing"
cd ${basedir}/tests

git clone git://github.com/n1k0/casperjs.git
cd casperjs
ln -sf `pwd`/bin/casperjs /usr/local/bin/casperjs

echo "Start testing of Freeciv-web using CasperJS:"
cd ${basedir}/tests/
xvfb-run casperjs --engine=phantomjs test freeciv-web-tests.js || (>&2 echo "Freeciv-web CasperJS tests failed!" && exit 1)

echo "=============================="
echo "Freeciv-web built, tested and started correctly: Build successful!"
