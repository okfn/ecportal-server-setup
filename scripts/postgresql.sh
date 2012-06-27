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
  
  # Allow postgres to accept local connections too
  service postgresql initdb
  sed -e '/^local/ s,ident,trust,' \
      -e '/^host.*/ s,ident,trust,' \
      -e "/^host.*${CKAN_BACKEND_SERVER}/ s,^,#," \
      -i $POSTGRES_PRODUCT/pgsql/data/pg_hba.conf

  # If the backend server is not local, then
  # allow postgresql to accept non-local connections too
  if [ ! "$CKAN_BACKEND_SERVER" == "0.0.0.0" ]
  then

    # remove all previous reference to the same backend server
    sed -e "/^host  all all ${CKAN_BACKEND_SERVER}  ident$/d"
        -i $POSTGRES_PRODUCT/pgsql/data/pg_hba.conf

    echo "host  all all ${CKAN_BACKEND_SERVER}  ident" >> $POSTGRES_PRODUCT/pgsql/data/pg_hba.conf
  fi

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
