#!/bin/sh

## Usage:
##
## Source this file, and run install_postgresql()
##
## This requires the following environment variables to be set:
##
## $CKAN_APPLICATION       : The location of the CKAN application,
##                           eg - /applications/ckan/users/system
## $CKAN_INSTANCE          : The CKAN instance name
## $CKAN_DATABASE_PASSWORD : The Postgres DB password.

if [ "X" == "X$CKAN_APPLICATION" ]
then
  echo 'ERROR: CKAN_APPLICATION environment variable is not set'
  exit 1
fi

if [ "X" == "X$CKAN_INSTANCE" ]
then
  echo 'ERROR: CKAN_INSTANCE environment variable is not set'
  exit 1
fi

if [ "X" == "X$CKAN_DATABASE_PASSWORD" ]
then
  echo 'ERROR: CKAN_DATABASE_PASSWORD environment variable is not set'
  exit 1
fi

# Location of posgres within the CKAN_APPLICATION strucuter. 
POSTGRES_PRODUCT=$CKAN_APPLICATION/postgres

# Call this to install postgres.
# It's safe to call this more than once.  However, the
# soft-linking will fail on subsequent runs as the file(s)
# alreay exist.
install_postgresql () {

  echo '------------------------------------------'
  echo 'Installing postgresql                     '
  echo '------------------------------------------'

  yum install -y postgresql postgresql-server

  if [[ $? -ne 0 ]]; then
    echo 'Could not install dependencies from the configured yum repos'
    exit 1
  fi

  mkdir -p $POSTGRES_PRODUCT
  ln -s /etc/init.d/postgresql $CKAN_APPLICATION/init.d/postgresql
  ln -s /var/lib/pgsql $POSTGRES_PRODUCT/pgsql
  
  # By default, allow postgres to accept local connections as trusted.
  service postgresql initdb
  sed -e '/^local/ s,ident,trust,' \
      -e '/^host.*127\.0\.0\.1/ s,ident,trust,' \
      -i $POSTGRES_PRODUCT/pgsql/data/pg_hba.conf

  # This script sets a marker in the file, after which any content
  # will be overwritten when/if this script runs again.
  # Delete all lines after (and including) the marker line
  sed -e '/#### LINES BELOW ADDED BY ECODP INSTALLATION SCRIPTS ####/,$d' \
      -i $POSTGRES_PRODUCT/pgsql/data/pg_hba.conf

  # Append customized connection configuration, as defined in the installation
  # script's config file, config.sh
  echo '#### LINES BELOW ADDED BY ECODP INSTALLATION SCRIPTS ####' >> $POSTGRES_PRODUCT/pgsql/data/pg_hba.conf
  echo $PG_HBA_CONF >> $POSTGRES_PRODUCT/pgsql/data/pg_hba.conf

  sed -e "s/^#listen_addresses =.*/listen_addresses = '*'/" \
      -i $POSTGRES_PRODUCT/pgsql/data/postgresql.conf
  
  chkconfig postgresql on --level 345
  chkconfig --list postgresql

  /etc/init.d/postgresql restart
  $CKAN_APPLICATION/init.d/postgresql restart

  echo '------------------------------------------'
  echo 'Creating Postgresql DB and user'
  echo '------------------------------------------'

  source common.sh
  ckan_add_or_replace_database_user $CKAN_INSTANCE $CKAN_DATABASE_PASSWORD
  ckan_ensure_db_exists $CKAN_INSTANCE
}
