#!/bin/sh

## Usage:
##
## Source this file, and run install_solr()
##
## This requires the following environment variables to be set:
##
## $CKAN_APPLICATION    : The location of the CKAN application,
##                        eg - /applications/ckan/users/system
## $CKAN_BACKEND_SERVER : The ip address or name of the backend server.

if [ "X" == "X$CKAN_BACKEND_SERVER" ]
then
  echo 'ERROR: CKAN_BACKEND_SERVER environment variable is not set'
  exit 1
fi
  
if [ "X" == "X$CKAN_APPLICATION" ]
then
  echo 'ERROR: CKAN_APPLICATION environment variable is not set'
  exit 1
fi

if [ "X" == "X$CKAN_USER" ]
then
  echo 'ERROR: CKAN_USER environment variable is not set'
  exit 1
fi

# Locations of solr and tomcat within the CKAN_APPLICATION structure. 
SOLR_PRODUCT=$CKAN_APPLICATION/solr
TOMCAT_PRODUCT=$CKAN_APPLICATION/tomcat

# Call this to install solr.
# It may be called more than once.  In such a case the creation
# of existing soft-links will fail, but other than it should be
# fine to run this more than once.
install_solr () {

  echo '------------------------------------------'
  echo 'Installing solr'
  echo '------------------------------------------'

  echo 'Installing tomcat...'
  yum install -y tomcat6
  
  if [[ $? -ne 0 ]]; then
    echo 'Could not install dependencies from the configured yum repos'
    exit 1
  fi

  echo 'Linking to tomcat lib and configuration...'
  mkdir -p $SOLR_PRODUCT
  mkdir -p $TOMCAT_PRODUCT
  ln -s /var/lib/tomcat6 $TOMCAT_PRODUCT/lib
  ln -s /etc/tomcat6 $TOMCAT_PRODUCT/etc
  ln -s /etc/init.d/tomcat6 $CKAN_APPLICATION/init.d/tomcat6
  
  echo "Installing solr"
  PREV_DIR=$PWD
  cd $SCRIPTS_HOME/../downloads
  tar xzf apache-solr-1.4.1.tgz
  
  cp $SCRIPTS_HOME/../downloads/apache-solr-1.4.1/dist/apache-solr-1.4.1.war $TOMCAT_PRODUCT/lib/webapps/solr.war
  cp -R $SCRIPTS_HOME/../downloads/apache-solr-1.4.1/example/solr $SOLR_PRODUCT/solr/

  # Check if the file has already been modified.
  egrep "$SOLR_PRODUCT" $TOMCAT_PRODUCT/etc/tomcat6.conf
  if [[ $? -ne 0 ]]; then
    echo "JAVA_OPTS=\"\${JAVA_OPTS} -Dsolr.solr.home=$SOLR_PRODUCT/solr\"" >> $TOMCAT_PRODUCT/etc/tomcat6.conf
  fi
  
  # Set the data directory
  mkdir -p $SOLR_PRODUCT/data
  sed -e "s,<dataDir>\${solr.data.dir:./solr/data}</dataDir>,<dataDir>\${solr.data.dir:$SOLR_PRODUCT/data}</dataDir>," \
      -i $SOLR_PRODUCT/solr/conf/solrconfig.xml
  chown tomcat:$CKAN_USER -R $SOLR_PRODUCT
  
  # Change the port number tomcat listens on from 8080 8983
  sed -e 's,port="8080",port="8983",' \
      -i $TOMCAT_PRODUCT/etc/server.xml
  
  # start the server
  $CKAN_APPLICATION/init.d/tomcat6 restart
  sleep 5
  # Check the installation...
  curl http://${CKAN_BACKEND_SERVER}:8983/solr/admin/ping

  cd "$PREV_DIR"

  echo '------------------------------------------'
  echo 'Installing multilingual solr schema       '
  echo '------------------------------------------'

  cd $SCRIPTS_HOME/../downloads
  tar -xf solr_schema.tar.gz
  
  cp solr_schema/* $SOLR_PRODUCT/solr/conf/
  /etc/init.d/tomcat6 restart
  sleep 5
  curl http://${CKAN_BACKEND_SERVER}:8983/solr/admin/ping

  # Ensure solr is started on boot.
  chkconfig tomcat6 on --level 345
  chkconfig --list tomcat6

  cd "$PREV_DIR"
}
