#!/bin/sh

## Usage:
##
## Source this file, and run download_dependencies()

download_dependencies () {
  sudo yum install wget

  echo '------------------------------------------'
  echo 'Downloading Dependency Files              '
  echo '------------------------------------------'

  PREV_DIR=$PWD
  cd ../downloads

  echo 'Downloading solr'
  wget http://mirrors.ukfast.co.uk/sites/ftp.apache.org/lucene/solr/1.4.1/apache-solr-1.4.1.tgz

  echo 'Downloading EC ODP multilingual solr files'
  git clone https://github.com/okfn/ckanext-ecportal.git
  mv ckanext-ecportal/ckanext/ecportal/solr solr_schema
  tar -cf solr_schema.tar.gz solr_schema
  rm -rf solr_schema
  rm -rf ckanext-ecportal

  echo 'Downloading elastic search'
  wget https://github.com/downloads/elasticsearch/elasticsearch/elasticsearch-0.19.4.tar.gz

  cd ../rpms
  echo 'Downloading nginx rpm'
  wget http://nginx.org/packages/rhel/6/x86_64/RPMS/nginx-1.2.2-1.el6.ngx.x86_64.rpm

  cd $PREV_DIR
}
