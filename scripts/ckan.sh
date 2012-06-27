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

PASTER=$PYENV/bin/paster
PIP=$PYENV/bin/pip
INI_FILE="$CKAN_ETC/$CKAN_INSTANCE/$CKAN_INSTANCE.ini"

install_python_dependencies_from_source () {
  
  echo '------------------------------------------'
  echo 'Installing python dependencies from source'
  echo '------------------------------------------'

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
  $PIP install -e "git+https://github.com/okfn/ckanext-ecportal.git#egg=ckanext-ecportal"
  [ $? -ne 0 ] && echo "ERROR: failure to install ckanext-ecportal and dependencies" && exit 1

  $PIP install -e "git+https://github.com/okfn/ckanext-archiver.git@release-v1.7.1#egg=ckanext-archiver"
  [ $? -ne 0 ] && echo "ERROR: failure to install ckanext-archiver and dependencies" && exit 1

  $PIP install -e "git+https://github.com/okfn/ckanext-qa.git@release-v1.7.1#egg=ckanext-qa"
  [ $? -ne 0 ] && echo "ERROR: failure to install ckanext-qa and dependencies" && exit 1

  $PIP install -e "git+https://github.com/okfn/ckanext-datastorer.git#egg=ckanext-datastorer"
  [ $? -ne 0 ] && echo "ERROR: failure to install ckanext-datastorer and dependencies" && exit 1

}

install_python_dependencies_from_rpm () {
  echo '------------------------------------------'
  echo 'Installing python dependencies from RPM   '
  echo '------------------------------------------'

	echo "Installing from $SCRIPTS_HOME/../rpms/$PYENV_RPM"
	rpm -i $SCRIPTS_HOME/../rpms/$PYENV_RPM
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
  yum install -y python postgresql-devel postgresql postgresql-server libxml2 libxslt gcc gcc-c++ glibc-devel make python-devel libxml2 libxml2-devel libxslt-devel mod_wsgi
  
  if [[ $? -ne 0 ]]; then
    echo 'Could not install dependencies from the configured yum repos'
    exit 1
  fi

  echo '------------------------------------------'
  echo 'Setting up apache'
  echo '------------------------------------------'
  cat <<EOF > /etc/httpd/conf.d/0-wsgi.conf
LoadModule wsgi_module modules/mod_wsgi.so
WSGISocketPrefix /var/run/wsgi
EOF
  
  cat <<EOF > /etc/httpd/conf.d/0-rewrite.conf
LoadModule rewrite_module modules/mod_rewrite.so
EOF

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
  chcon -R --type=httpd_sys_content_t $CKAN_APPLICATION/ckan

  echo 'Setting apache to run at boot...'
  ln -s /etc/init.d/httpd $CKAN_APPLICATION/init.d/httpd
  chkconfig httpd on --level 345
  chkconfig --list httpd

  echo '------------------------------------------'
  echo 'Setting up python virtualenv              '
  echo '------------------------------------------'
  easy_install --upgrade pip "pip>=1.0" "pip<=1.0.99"
  pip install virtualenv
  
  mkdir -p "$PYENV"
  cd "$PYENV"
  virtualenv --no-site-packages .

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
  ./ckan-create-instance $CKAN_INSTANCE $CKAN_DOMAIN no $CKAN_LIB $CKAN_ETC $CKAN_USER

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

  sed -e "s/^email_to =.*/email_to = john.glover@okfn.org, david.raznick@okfn.org, ian.murray@okfn.org/" \
      -e "s/^error_email_from =.*/error_email_from = admin@$CKAN_DOMAIN/" \
      -e "s/^ckan\.plugins =.*/ckan.plugins = synchronous_search ecportal ecportal_form ecportal_publisher_form ecportal_controller multilingual_dataset multilingual_group multilingual_tag qa datastorer/" \
      -e "s,^#\?licenses_group_url =.*,licenses_group_url = file://$PYENV/src/ckanext-ecportal/licenses.json," \
      -e "s/^ckan\.site_title =.*/ckan.site_title = Open Data Portal/" \
      -e "s,^ckan\.site_logo =.*,ckan.site_logo = /images/logo.png," \
      -e "s/^ckan\.site_description =.*/ckan.site_description = The EU Open Data Hub/" \
      -e "s,^ckan\.site_url =.*,ckan.site_url = http://$CKAN_DOMAIN/open-data/data/," \
      -e "s,^ckan\.favicon =.*,ckan.favicon = /images/favicon.ico," \
      -e "s/^ckan\.site_id =.*/ckan.site_id = ecportal/" \
      -e 's|^ckan.default_roles.Package =.*|ckan.default_roles.Package = {"visitor": ["reader"], "logged_in": ["reader"]}|' \
      -e 's|^ckan.default_roles.Group =.*|ckan.default_roles.Group = {"visitor": ["reader"], "logged_in": ["reader"]}|' \
      -e 's|^ckan.default_roles.System =.*|ckan.default_roles.System = {"visitor": ["reader"], "logged_in": ["reader"]}|' \
      -e 's|^ckan.default_roles.AuthorizationGroup =.*|ckan.default_roles.AuthorizationGroup = {"visitor": ["reader"], "logged_in": ["reader"]}|' \
      -e "s/^ckan\.locale_default =.*/ckan.locale_default = en/" \
      -e "s/^#ckan\.locales_offered =.*/ckan.locales_offered = en de es fr it pl/" \
      -e "s/^ckan\.locale_order =.*/ckan.locale_order = en bg cs da de et el es fr ga it lv lt hu mt nl pl pt ro sk sl fi sv/" \
      -e "s/^ckan\.locales_filtered_out =.*/ckan.locales_filtered_out = pt_BR sr_Latn zh_TW ca cs_CZ no ru sq sr/" \
      -e "s/^# ckan\.datastore\.enabled = 1/ckan.datastore.enabled = 1/" \
      -e "/^\[app:main\]$/ a\
ckan.root_path = /open-data/{{LANG}}/data\\
ckan.tracking_enabled = true\\
ckan.i18n_directory = $PYENV/src/ckanext-ecportal/ckanext/ecportal\\
ckan.search_facets = groups tags res_format license_id vocab_language vocab_geographical_coverage\\
ckan.default.group_type = organization\\
qa.organisations = false\\
" \
      -i $INI_FILE


  echo '------------------------------------------'
  echo 'Running internal analytics tracking command'
  echo '------------------------------------------'
  Old_DIR=$PWD
  cd $PYENV/src/ckan
  $PASTER tracking -c $INI_FILE
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
  $PIP install pairtree
  sed -e "/^\[app:main\]$/ a\
ofs.impl = pairtree\\
ofs.storage_dir = $CKAN_LIB/$CKAN_INSTANCE/file-storage\\
" \
      -i $INI_FILE

  echo 'Ensuring selinux permissions are set'
  chcon -R --type=httpd_sys_content_t $CKAN_APPLICATION/ckan

  echo 'Restarting all services'

  if [ $CKAN_BACKEND_SERVER == "0.0.0.0" ]
  then
    $CKAN_APPLICATION/init.d/elasticsearch restart
    $CKAN_APPLICATION/init.d/postgresql restart
    $CKAN_APPLICATION/init.d/tomcat6 restart
  fi

  $CKAN_APPLICATION/init.d/nginx restart
  $CKAN_APPLICATION/init.d/supervisord restart
  $CKAN_APPLICATION/init.d/httpd restart
}
