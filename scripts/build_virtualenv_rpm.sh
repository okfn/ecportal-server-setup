#!/bin/sh

## Usage:
##
## Source this file, and run build_virtualenv_rpm()
##
## This requires the following environment variables to be set:
##
## $PYENV    : The location of the virtual environment

if [ "X" == "X$PYENV" ]
then
  echo 'ERROR: PYENV environment variable is not set'
  exit 1
fi

build_virtualenv_rpm () {
  
  echo '------------------------------------------'
  echo 'Building RPM of virtual environment       '
  echo '------------------------------------------'

  echo 'Installing dependencies for fpm'
  yum install -y ruby ruby-devel rubygems rpm-build
  gem install fpm

  echo 'Building package'
  fpm -s dir -t rpm -n 'ecportal-python-virtual-environment' -v 1.0 -a all $PYENV

}
