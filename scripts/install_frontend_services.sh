#!/bin/bash

# This script must be run as root.
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

echo 'Checking configuration...'
SCRIPTS_HOME="$( cd "$( dirname "$0" )" && pwd )"
cd $SCRIPTS_HOME
source $SCRIPTS_HOME/config $SCRIPTS_HOME

if [[ $? -ne 0 ]]; then
  exit 1
fi

echo '------------------------------------------'
echo 'Checking connections to backend servives.'
echo '------------------------------------------'

echo "Checking connection to postgresql on ${CKAN_BACKEND_SERVER} (DB: ${INSTANCE})"
psql --host=${CKAN_BACKEND_SERVER} --port=5432 ${INSTANCE} ${INSTANCE} --list

if [[ $? -ne 0 ]]; then
  echo 'ERROR: Cannot connect to postgresql database.'
  exit 1
fi

echo "Checking connection to elasticsearch on ${CKAN_BACKEND_SERVER}"
curl http://${CKAN_BACKEND_SERVER}:8983/solr/admin/ping

if [[ $? -ne 0 ]]; then
  echo 'ERROR: Cannot ping solr database.'
  exit 1
fi

echo "Checking connection to solr on ${CKAN_BACKEND_SERVER}"
curl http://${CKAN_BACKEND_SERVER}:9200/_status

if [[ $? -ne 0 ]]; then
  echo 'ERROR: Cannot ping elasticsearch.'
  exit 1
fi


source common_step1.sh

source nginx.sh
install_nginx

source solr.sh
source ckan.sh
install_ckan
