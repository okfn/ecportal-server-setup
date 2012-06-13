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

source common_step1.sh

source nginx.sh
install_nginx

source solr.sh
source ckan.sh
install_ckan
