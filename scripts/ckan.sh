#!/bin/sh

## Usage:
##
## Source this file, and run install_ckan()
##
## This requires the following environment variables to be set:
##
## $CKAN_APPLICATION       : The location of the CKAN application,
##                           eg - /applications/ckan/users/system
## $PYENV                  : The location of the python environment.
## $SOLR_PRODUCT           : The location of the solr installation
## $CKAN_DATABASE_PASSWORD : The CKAN database password
## $PACKAGE_INSTALL        : Whether to install the python dependencies
##                           from an RPM or not.
## $PYENV_RPM              : The name of RPM to use to install the
##                           python dependencies.
## $CKAN_BACKEND_SERVER    : The ip or name of the server hosting the
##                           backend services.

if [ "X" == "X$CKAN_APPLICATION" ]
then
  echo 'ERROR: CKAN_APPLICATION environment variable is not set'
  exit 1
fi

if [ "X" == "X$PYENV" ]
then
  echo 'ERROR: PYENV environment variable is not set'
  exit 1
fi

if [ "X" == "X$SOLR_PRODUCT" ]
then
  echo 'ERROR: SOLR_PRODUCT environment variable is not set'
  exit 1
fi

if [ "X" == "X$CKAN_DATABASE_PASSWORD" ]
then
  echo 'ERROR: CKAN_DATABASE_PASSWORD environment variable is not set'
  exit 1
fi

if [ "X" == "X$CKAN_USER" ]
then
  echo 'ERROR: CKAN_USER environment variable is not set'
  exit 1
fi

if [ ! "yes" == "$PACKAGE_INSTALL" ] && [ ! "no" == "$PACKAGE_INSTALL" ]
then
  echo 'ERROR: PACKAGE_INSTALL environment variable is not set to either "yes" or "no"'
  exit 1
fi

if [ "X" == "X$PYENV_RPM" ]
then
  echo 'ERROR: PYENV_RPM environment variable is not set'
  exit 1
fi

if [ ! "yes" == "$OVERWRITE_APACHE_CONFIG" ] && [ ! "no" == "$OVERWRITE_APACHE_CONFIG" ]
then
  echo 'ERROR: OVERWRITE_APACHE_CONFIG environment variable is not set to either "yes" or "no"'
  exit 1
fi

PASTER=$PYENV/bin/paster
PIP=$PYENV/bin/pip
INI_FILE="$CKAN_ETC/$CKAN_INSTANCE/$CKAN_INSTANCE.ini"

install_python_dependencies_from_source () {
  
  echo '------------------------------------------'
  echo 'Installing python dependencies from source'
  echo '------------------------------------------'

  easy_install --upgrade pip "pip>=1.0" "pip<=1.0.99"
  pip install virtualenv
  
  mkdir -p "$PYENV"
  cd "$PYENV"
  virtualenv --no-site-packages .

	$PIP install pastescript

  echo '------------------------------------------'
  echo 'Downloading and installing CKAN into pyenv'
  echo '------------------------------------------'
  # Installing CKAN into the python virtual environment
  $PIP install --ignore-installed -e "git+https://github.com/okfn/ckan.git@${CKAN_VERSION}#egg=ckan"
  
  echo '------------------------------------------'
  echo 'Installing CKAN python dependencies       '
  echo '------------------------------------------'
  
  # Installing CKAN's python dependencies into the python virtual environment
  # This step may take quite a while due to the need to download quite
  # a few python libraries.  Also, it's prone to failure as it's reliant
  # on a number of sources.
  $PIP install --ignore-installed -r $PYENV/src/ckan/requires/lucid_missing.txt \
                                  -r $PYENV/src/ckan/requires/lucid_conflict.txt \
                                  -r $PYENV/src/ckan/requires/lucid_present.txt
  
  if [ $? -ne 0 ]
  then
      echo "WARNING: Failed to install all of CKAN's dependencies"
      echo "... Trying once more..."
      $PIP install --ignore-installed -r $PYENV/src/ckan/requires/lucid_missing.txt \
                                      -r $PYENV/src/ckan/requires/lucid_conflict.txt \
                                      -r $PYENV/src/ckan/requires/lucid_present.txt
  
      if [ $? -ne 0 ]
      then
              echo "ERROR: Failed to install all of CKAN's dependencies"
              exit 1
      fi
  fi

  echo '------------------------------------------'
  echo 'Installing ckanext-ecportal dependencies  '
  echo '------------------------------------------'

  ## Upgraded version of paste is required becase there's a bug in the gzip middleware
  ## in pip 1.7.2.  The bug causes empty responses to not be handled correctly, eg.
  ## a 302 redirection.  And the ECODP project uses paste's Gzip middleware to compress
  ## responses.
  $PIP install paste==1.7.5.1
  [ $? -ne 0 ] && echo "ERROR: failure to install paste==1.7.5.1" && exit 1

  $PIP install -e "git+https://github.com/okfn/ckanext-ecportal.git#egg=ckanext-ecportal"
  [ $? -ne 0 ] && echo "ERROR: failure to install ckanext-ecportal and dependencies" && exit 1

  $PIP install -e "git+https://github.com/okfn/ckanext-archiver.git@release-v1.7.1#egg=ckanext-archiver"
  [ $? -ne 0 ] && echo "ERROR: failure to install ckanext-archiver and dependencies" && exit 1

  $PIP install -e "git+https://github.com/okfn/ckanext-qa.git@release-v1.7.1#egg=ckanext-qa"
  [ $? -ne 0 ] && echo "ERROR: failure to install ckanext-qa and dependencies" && exit 1

  $PIP install -e "git+https://github.com/okfn/ckanext-datastorer.git@ff35ae#egg=ckanext-datastorer"
  [ $? -ne 0 ] && echo "ERROR: failure to install ckanext-datastorer and dependencies" && exit 1

}

install_python_dependencies_from_rpm () {
  echo '------------------------------------------'
  echo 'Installing python dependencies from RPM   '
  echo '------------------------------------------'

	local rpm_file
	rpm_file=$SCRIPTS_HOME/../rpms/$PYENV_RPM

  if [ ! -f $rpm_file ]
  then
    echo "ERROR: Couldn't find python dependency rpm in required location: $rpm_file"
    exit 1
  fi

	echo 'Checking the rpm has been built for this installation...'
	local num_files num_matching_files
	num_files=`rpm -qpl $rpm_file  |  wc -l`
	num_matching_files=`rpm -qpl $rpm_file | egrep "^$PYENV" | wc -l`

	if [ ! $num_files == $num_matching_files ]
	then
		echo 'ERROR: This rpm appears to have been built for a different pyenv location:'
		rpm -qpl $rpm_file | head -1
		echo '       Cannot install python dependencies...'
		exit 1
	fi

	echo "Installing from $rpm_file"
	rpm --upgrade $rpm_file
}

install_ckan () {
  echo '------------------------------------------'
  echo 'Installing CKAN                           '
  echo '------------------------------------------'

  mkdir -p $CKAN_APPLICATION/ckan

  echo '------------------------------------------'
  echo 'Installing dependencies                   '
  echo '------------------------------------------'

  # Install direct dependencies of CKAN
  yum install -y python postgresql libxml2 libxslt mod_wsgi

  if [[ $? -ne 0 ]]; then
    echo 'Could not install dependencies from the configured yum repos'
    exit 1
  fi

  if [ "no" == "$PACKAGE_INSTALL" ]
	then
    echo "Installing further packages required to build CKAN's python dependencies"
    yum install -y python postgresql-devel postgresql libxml2 libxslt gcc gcc-c++ glibc-devel make python-devel libxml2 libxml2-devel libxslt-devel mod_wsgi
    if [[ $? -ne 0 ]]; then
      echo 'Could not install further dependencies from the configured yum repos'
      exit 1
    fi
	fi

  echo '------------------------------------------'
  echo 'Setting up apache'
  echo '------------------------------------------'
  echo 'Creating (non-shared) apache config file: /etc/httpd/conf.d/0-wsgi.conf'
  cat <<EOF > /etc/httpd/conf.d/0-wsgi.conf
LoadModule wsgi_module modules/mod_wsgi.so
WSGISocketPrefix /var/run/wsgi
EOF
  
  echo 'Creating (non-shared) apache config file: /etc/httpd/conf.d/0-rewrite.conf'
  cat <<EOF > /etc/httpd/conf.d/0-rewrite.conf
LoadModule rewrite_module modules/mod_rewrite.so
EOF

  echo 'Modifying /etc/httpd/conf/httpd.conf to listen on port 8008'
  # Listen on port 8008 as nginx is listening on 80.
  sed -e 's/^Listen 80$/Listen 8008/' \
      -i /etc/httpd/conf/httpd.conf
  
  # Configure selinux
  # 1. Allow httpd (sub-)processes to make network connections,
  #    for accessing solr, DB etc.
  setsebool -P httpd_can_network_connect_db=1
  setsebool -P httpd_can_network_connect=1
  setsebool -P httpd_can_sendmail=1

  # 2. Make ckan "executable" by httpd
	semanage fcontext -a -t httpd_sys_content_t $CKAN_APPLICATION/ckan
	restorecon -FR $CKAN_APPLICATION/ckan

  echo 'Setting apache to run at boot...'
  ln -s /etc/init.d/httpd $CKAN_APPLICATION/init.d/httpd
  chkconfig httpd on --level 345
  chkconfig --list httpd

  # Require apache user to be a member of $CKAN_INSTANCE group
  # in order that it can be granted read-access to the CKAN
  # configuration files.  These files don't have global read-access
  # because they contain sensitive configuration data, including
  # the database password.
  echo "Adding apache user to group '$CKAN_INSTANCE'"
  usermod --append --groups "$CKAN_INSTANCE" apache

  echo '------------------------------------------'
  echo 'Setting up python virtualenv              '
  echo '------------------------------------------'
	# Python dependencies can either be installed from source,
	# or from a prebuilt RPM.  The default is the RPM install.
	if [ "yes" == "$PACKAGE_INSTALL" ]
	then
		install_python_dependencies_from_rpm
	else
		install_python_dependencies_from_source
	fi

  echo "------------------------------------------"
  echo "Creating new CKAN instance: $CKAN_INSTANCE"
  echo "------------------------------------------"
  
  cd $SCRIPTS_HOME

  if [ ! -f ./common.sh ]
  then
    echo 'Cannot find file common.sh'
    exit
  fi

  if [ ! -f ./ckan-create-instance ]
  then
    echo 'Cannot find file ckan-create-instance'
    exit
  fi

  source $PYENV/bin/activate
  source ./common.sh
  ./ckan-create-instance $CKAN_INSTANCE $CKAN_DOMAIN no $CKAN_LIB $CKAN_ETC $CKAN_USER $CKAN_APPLICATION $OVERWRITE_APACHE_CONFIG $CKAN_DATABASE_PASSWORD

  # Configure the new instance's ini file
  echo 'Setting database connection strings...'
  sed \
    -e "s,^sqlalchemy\.url =.*,sqlalchemy.url = postgresql://${CKAN_INSTANCE}:${CKAN_DATABASE_PASSWORD}@${CKAN_BACKEND_SERVER}/${CKAN_INSTANCE}," \
    -e "s,^solr_url =.*,solr_url = http://${CKAN_BACKEND_SERVER}:8983/solr," \
    -i $INI_FILE

  $PASTER --plugin=ckan db init --config=$CKAN_ETC/${CKAN_INSTANCE}/${CKAN_INSTANCE}.ini
  deactivate

  echo 'Creating log dirs'
  mkdir -p $CKAN_APPLICATION/ckan/var/log

  echo '------------------------------------------'
  echo 'Customising ecportal .ini file.'
  echo '------------------------------------------'

  if [ -f "$INI_FILE" ]
  then
    local BACKUP_INI_FILE="$INI_FILE.bak-`date +%F_%T`"
    echo "Backing up existing ini file $INI_FILE to $BACKUP_INI_FILE"
    cp -f "$INI_FILE" "$BACKUP_INI_FILE"
  fi

  sed -e "s/\\\${CKAN_ERROR_EMAIL_FROM}/$CKAN_ERROR_EMAIL_FROM/g" \
      -e "s,\\\${PYENV},$PYENV,g" \
      -e "s/\\\${CKAN_DOMAIN}/$CKAN_DOMAIN/g" \
      -e "s,\\\${CKAN_LIB},$CKAN_LIB,g" \
      -e "s/\\\${CKAN_INSTANCE}/$CKAN_INSTANCE/g" \
      "$SCRIPTS_HOME/resources/ecodp.ini.tmpl" > "$INI_FILE"

  echo '------------------------------------------'
  echo 'Running internal analytics tracking command'
  echo '------------------------------------------'
  Old_DIR=$PWD
  cd $PYENV/src/ckan
  $PASTER tracking update -c $INI_FILE
  cd "$OLD_DIR"


  echo "Setting file permmissions on $CKAN_APPLICATION/ckan"
  chown -R $CKAN_USER "$CKAN_APPLICATION/ckan"
  chgrp -R $CKAN_USER "$CKAN_APPLICATION/ckan"
  chown -R apache $CKAN_LIB/$CKAN_INSTANCE/sstore
  chown -R apache $CKAN_LIB/$CKAN_INSTANCE/data

  echo '------------------------------------------'
  echo 'Generating ecportal vocabs'
  echo '------------------------------------------'

  OLD_DIR=$PWD

  cd $PYENV/src/ckanext-ecportal
  
  $PASTER ecportal create-all-vocabs -c $INI_FILE

  cd "$OLD_DIR"


  echo '---------------------------------------------'
  echo 'Setting up celeryd (running under supervisord'
  echo '---------------------------------------------'

  cd $SCRIPTS_HOME
  source ./supervisor.sh
  install_supervisor

  source ./celery.sh
  install_celery

  echo '---------------------------------------------'
  echo 'Configuring uploads'
  echo '---------------------------------------------'

  mkdir -p $CKAN_LIB/$CKAN_INSTANCE/file-storage
  chown apache -R $CKAN_LIB/$CKAN_INSTANCE/file-storage
  chgrp $CKAN_USER -R $CKAN_LIB/$CKAN_INSTANCE/file-storage

  if [ "no" == "$PACKAGE_INSTALL" ]
  then
    # Install pairtree from source if required.
    $PIP install pairtree
  fi

  echo 'CKAN config already configured for uploads...'

  echo 'Ensuring selinux permissions are set'
	semanage fcontext -a -t httpd_sys_content_t $CKAN_APPLICATION/ckan
	restorecon -FR $CKAN_APPLICATION/ckan

  echo 'Restarting all services'

  if [ $CKAN_BACKEND_SERVER == "0.0.0.0" ] || [ $CKAN_BACKEND_SERVER == "localhost" ]]
  then
    $CKAN_APPLICATION/init.d/elasticsearch restart
    $CKAN_APPLICATION/init.d/postgresql restart
    $CKAN_APPLICATION/init.d/tomcat6 restart
  fi

  $CKAN_APPLICATION/init.d/nginx restart
  $CKAN_APPLICATION/init.d/supervisord restart
  $CKAN_APPLICATION/init.d/httpd restart

  
  echo '---------------------------------------------'
  echo 'Creating cronjobs'
  echo '---------------------------------------------'

  cat <<EOF | crontab -u $CKAN_USER -
0 0 * * * $PASTER --plugin=ckan rdf-export -c $INI_FILE $RDF_EXPORT_DUMP_LOCATION
0 2 * * 1 $PASTER --plugin=ckan tracking update -c $INI_FILE
EOF

  cat <<EOF | crontab -u apache -
0 1 * * * find /applications/ecodp/users/ecodp/ckan/lib/ecodp/data/ -type f -amin +5000 -delete
EOF

}
