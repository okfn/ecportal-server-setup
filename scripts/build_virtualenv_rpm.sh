#!/bin/sh

## Usage:
##
## Source this file, and run build_virtualenv_rpm()
##
## This requires the following environment variables to be set:
##
## $PYENV    : The location of the virtual environment
##
## Please note, this is a very naive packaging script.  It makes
## the assumption that all the configuration is identical
## on the machine that's building the RPM as on the machine
## that it will be installed on.  In particular, the location
## of the virtualenv.  It's not sufficient to use the
## `--relocation` flag of the rpm tool when installing this
## rpm because the of the `bin/activate` shell script in
## particular: it has the location of the virtualenv  hard-coded
## within it.

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
  fpm -s dir -t rpm -n 'ecportal-python-virtual-environment' -v 1.7.1 -a x86_64 $PYENV

}
