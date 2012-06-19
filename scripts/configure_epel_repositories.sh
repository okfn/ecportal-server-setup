#!/bin/sh

## Usage:
##
## Source this file, and run configure_epel_repositories()
##
## Only use this if the RHEL repositories do not contain the
## necessary packages.
##
configure_epel_repositories () {

  echo '------------------------------------------'
  echo 'Configuring repositories'
  echo '------------------------------------------'

  if [[ `uname -a` =~ "x86_64" ]]; then
    ARCH="x86_64"
  else
    ARCH="i386"
  fi
 
  rpm -Uvh http://mirrors.coreix.net/fedora-epel//6/$ARCH/epel-release-6-7.noarch.rpm

}
