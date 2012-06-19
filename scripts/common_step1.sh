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

if [[ $? -ne 0 ]]; then
  echo 'Could not install dependencies from the configured yum repos'
  exit 1
fi

echo '------------------------------------------'
echo 'Ensuring CKAN Application directory exists'
echo '------------------------------------------'
mkdir -p $CKAN_APPLICATION/init.d
mkdir -p $CKAN_APPLICATION/users/okfn
ln -s /home/okfn $CKAN_APPLICATION/users/okfn
