#!/bin/sh

# This script must be run as root.
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

echo '------------------------------------------'
echo "Creating $CKAN_USER user"
echo '------------------------------------------'
id $CKAN_USER
if [[ $? -ne 0 ]]; then
  groupadd --system $CKAN_USER
  useradd -d /home/$CKAN_USER -m -s /bin/bash --gid $CKAN_USER $CKAN_USER
  echo "Please create a password for the $CKAN_USER user..."
  passwd $CKAN_USER
fi

echo '------------------------------------------'
echo 'Installing tools'
echo '------------------------------------------'

# Install some necessary tools.
yum install -y git wget policycoreutils-python python-setuptools

if [[ $? -ne 0 ]]; then
  echo 'Could not install dependencies from the configured yum repos'
  exit 1
fi

echo '------------------------------------------'
echo 'Ensuring CKAN Application directory exists'
echo '------------------------------------------'
mkdir -p $CKAN_APPLICATION/init.d
mkdir -p $CKAN_APPLICATION/users/$CKAN_USER
ln -s /home/$CKAN_USER $CKAN_APPLICATION/users/$CKAN_USER
