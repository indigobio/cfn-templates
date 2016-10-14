#!/bin/bash

# Run this on an Amazon Linux EC2 instance.

sudo yum -y update
sudo yum -y groupinstall "Development Tools"
sudo yum -y install openssl-devel
sudo yum -y install Cython --enablerepo=epel

wget https://ftp.postgresql.org/pub/source/v9.4.9/postgresql-9.4.9.tar.gz
wget http://initd.org/psycopg/tarballs/PSYCOPG-2-6/psycopg2-2.6.2.tar.gz
tar xzf postgresql-9.4.9.tar.gz
tar xzf psycopg2-2.6.2.tar.gz

cd postgresql-9.4.9
./configure --prefix=`pwd` --without-readline --without-zlib --with-openssl && make && make install
cd ..

mkdir /tmp/psycopg2
cd psycopg2-2.6.2
cat > setup.cfg <<EOF
[build_ext]
define =
use_pydatetime = 1
have_ssl = 1
pg_config = ../postgresql-9.4.9/bin/pg_config
static_libpq = 1

[egg_info]
tag_build =
tag_date = 0
tag_svn_revision = 0
EOF
python setup.py build
python setup.py install --root /tmp/psycopg2
cd ..

virtualenv /tmp/rds_create_role

pushd /tmp/psycopg2/usr/lib64/python2.7/dist-packages
tar cf - . | ( cd /tmp/rds_create_role/lib64/python2.7/site-packages ; tar xvpBf - )
popd

pushd /tmp/rds_create_role
zip -r /tmp/rds_create_role.zip .
popd

cp /tmp/rds_create_role.zip .
