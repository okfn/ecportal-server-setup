#!/bin/sh

# This script must be run as root.
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

echo '------------------------------------------'
echo 'Creating okfn user'
echo '------------------------------------------'
id okfn
if [[ $? -ne 0 ]]; then
  sudo groupadd --system okfn
  useradd -d /home/okfn -m -s /bin/bash --gid okfn okfn
  echo 'Please create a password for the okfn user...'
  passwd okfn

fi

echo '------------------------------------------'
echo 'Installing tools'
echo '------------------------------------------'

# Update local repository
yum update -y

# Install some necessary tools.
yum install -y vim mercurial git wget subversion screen lynx policycoreutils-python python-setuptools

echo '------------------------------------------'
echo 'Ensuring /applications directory exists   '
echo '------------------------------------------'
mkdir -p /applications/ckan/users/system/init.d
mkdir -p /applications/ckan/users/okfn
ln -s /home/okfn /applications/ckan/users/okfn

