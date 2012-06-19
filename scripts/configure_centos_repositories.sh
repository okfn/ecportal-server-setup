#!/bin/sh

## Usage:
##
## Source this file, and run configure_centos_repositories()
##
## Only use this if the RHEL repositories do not contain the
## necessary packages.
##
configure_centos_repositories () {

  echo '------------------------------------------'
  echo 'Configuring repositories'
  echo '------------------------------------------'

  echo 'Installing CentOS 6 GPG Key'
  rpm --import http://isoredirect.centos.org/centos/RPM-GPG-KEY-CentOS-6

  echo 'Adding CentOS-Base repository'
  cat << EOF > /etc/yum.repos.d/CentOS-Base.repo
# CentOS-Base.repo

[base]
name=CentOS-\$releasever - Base
baseurl=http://mirror.centos.org/centos/6.2/os/\$basearch/
gpgcheck=1
enabled=1
gpgkey=http://isoredirect.centos.org/centos/RPM-GPG-KEY-CentOS-6

#released updates 
[updates]
name=CentOS-\$releasever - Updates
baseurl=http://mirror.centos.org/centos/6.2/updates/\$basearch/
gpgcheck=1
enabled=1
gpgkey=http://isoredirect.centos.org/centos/RPM-GPG-KEY-CentOS-6

#additional packages that may be useful
[extras]
name=CentOS-\$releasever - Extras
baseurl=http://mirror.centos.org/centos/6.2/extras/\$basearch/
gpgcheck=1
enabled=1
gpgkey=http://isoredirect.centos.org/centos/RPM-GPG-KEY-CentOS-6
EOF

  yum clean all

}
