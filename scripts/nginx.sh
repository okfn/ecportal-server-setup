#!/bin/sh

## Usage:
##
## Source this file, and run install_nginx()
##
## This requires the following environment variables to be set:
##
## $CKAN_APPLICATION    : The location of the CKAN application,
##                        eg - /applications/ckan/users/system
## $CKAN_BACKEND_SERVER : The ip address or name of the 
##                        backend server.

if [ "X" == "X$CKAN_APPLICATION" ]
then
  echo 'ERROR: CKAN_APPLICATION environment variable is not set'
  exit 1
fi
  
if [ "X" == "X$CKAN_BACKEND_SERVER" ]
then
  echo 'ERROR: CKAN_BACKEND_SERVER environment variable is not set'
  exit 1
fi

if [[ `uname -a` =~ "x86_64" ]]; then
  ARCH="x86_64"
else
  ARCH="i386"
fi
 
# Location of nginx within the CKAN_APPLICATION structure.
NGINX_PRODUCT=$CKAN_APPLICATION/nginx

# Call this to install and configure nginx.  It's safe to call more than once.
install_nginx () {

  echo '------------------------------------------'
  echo 'Installing nginx                          '
  echo '------------------------------------------'
  cat <<EOF > /etc/yum.repos.d/nginx.repo
  
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/centos/6/$ARCH/
gpgcheck=0
enabled=1
  
EOF
  
  yum update
  yum install -y nginx
  
  rename '.conf' '' /etc/nginx/conf.d/*.conf
  cat <<EOF > /etc/nginx/conf.d/default.conf
server {

  listen 80;
  server_name $CKAN_DOMAIN;
  access_log  /var/log/nginx/$CKAN_DOMAIN.access.log;

  location /open-data/elastic/ {
    #internal;
    # location of elastic search
    proxy_pass http://${CKAN_BACKEND_SERVER}:9200/;
    proxy_set_header Host \$host;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  }

   location /open-data/ {
     proxy_pass http://0.0.0.0:8008;
     proxy_set_header Host \$host:80;
     proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
     proxy_set_header X-Scheme \$scheme;
  }
}

EOF
  
  echo 'Installing into $CKAN_APPLICATION'
  mkdir -p $NGINX_PRODUCT
  ln -s /etc/nginx $NGINX_PRODUCT/etc
  ln -s /etc/init.d/nginx $CKAN_APPLICATION/init.d/nginx

  chkconfig nginx on --level 345
  chkconfig --list nginx
  
  $CKAN_APPLICATION/init.d/nginx restart
  
}
