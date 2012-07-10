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
 
# Location of nginx within the CKAN_APPLICATION structure.
NGINX_PRODUCT=$CKAN_APPLICATION/nginx

# Call this to install and configure nginx.  It's safe to call more than once.
install_nginx () {

  echo '------------------------------------------'
  echo 'Installing nginx                          '
  echo '------------------------------------------'

  local rpm_file
  rpm_file=$SCRIPTS_HOME/../rpms/nginx-1.2.2-1.el6.ngx.x86_64.rpm

  echo "Installing from $rpm_file"
  rpm -i $rpm_file
  
  rename '.conf' '' /etc/nginx/conf.d/*.conf

  cat <<EOF > /etc/nginx/nginx.conf
user  nginx;
worker_processes  1;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] '
                      '$upstream_cache_status '
                      '$upstream_http_cache_control '
                      '"$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    proxy_cache_path $NGINX_PRODUCT/cache levels=1:2 keys_zone=cache:30m max_size=200m;
    proxy_temp_path $NGINX_PRODUCT/proxy 1 2;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    #gzip  on;

    include /etc/nginx/conf.d/*.conf;
}
EOF

  cat <<EOF > /etc/nginx/conf.d/default.conf
server {
  listen 80;
  server_name $CKAN_DOMAIN;
  access_log /var/log/nginx/$CKAN_DOMAIN.access.log main;

  location /open-data/elastic/ {
    internal;
    proxy_pass http://${CKAN_BACKEND_SERVER}:9200/;
    proxy_set_header Host \$host;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  }

  location /open-data/data {
     proxy_pass http://0.0.0.0:8008;
     proxy_set_header Host \$host:80;
     proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
     proxy_set_header X-Scheme \$scheme;
     proxy_cache cache;
     proxy_cache_bypass \$cookie_auth_tkt;
     proxy_no_cache \$cookie_auth_tkt;
     proxy_cache_valid 30m;
     proxy_cache_valid 404 5m;
  }

  location ~ /open-data/[a-zA-z][a-zA-z]/data$ {
     proxy_pass http://0.0.0.0:8008;
     proxy_set_header Host \$host:80;
     proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
     proxy_set_header X-Scheme \$scheme;
     proxy_cache cache;
     proxy_cache_bypass \$cookie_auth_tkt;
     proxy_no_cache \$cookie_auth_tkt;
     proxy_cache_valid 30m;
     proxy_cache_valid 404 5m;
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
  mkdir -p $NGINX_PRODUCT/cache
  mkdir -p $NGINX_PRODUCT/proxy
  ln -s /etc/nginx $NGINX_PRODUCT/etc
  ln -s /etc/init.d/nginx $CKAN_APPLICATION/init.d/nginx

  chkconfig nginx on --level 345
  chkconfig --list nginx
  
  $CKAN_APPLICATION/init.d/nginx restart
}
