#!/bin/bash

ckan_log () {
    echo "ckan: " $1
}

ckan_set_log_file_permissions () {
    local INSTANCE
    INSTANCE=$1
    sudo chown apache:ckan${INSTANCE} /var/log/ckan/${INSTANCE}
    sudo chmod g+w /var/log/ckan/${INSTANCE}
    sudo touch /var/log/ckan/${INSTANCE}/${INSTANCE}.log
    sudo touch /var/log/ckan/${INSTANCE}/${INSTANCE}1.log
    sudo touch /var/log/ckan/${INSTANCE}/${INSTANCE}2.log
    sudo touch /var/log/ckan/${INSTANCE}/${INSTANCE}3.log
    sudo touch /var/log/ckan/${INSTANCE}/${INSTANCE}4.log
    sudo touch /var/log/ckan/${INSTANCE}/${INSTANCE}5.log
    sudo touch /var/log/ckan/${INSTANCE}/${INSTANCE}6.log
    sudo touch /var/log/ckan/${INSTANCE}/${INSTANCE}7.log
    sudo touch /var/log/ckan/${INSTANCE}/${INSTANCE}8.log
    sudo touch /var/log/ckan/${INSTANCE}/${INSTANCE}9.log
    sudo chmod g+w /var/log/ckan/${INSTANCE}/${INSTANCE}*.log
    sudo chown apache:ckan${INSTANCE} /var/log/ckan/${INSTANCE}/${INSTANCE}*.log
}

ckan_ensure_users_and_groups () {

    local INSTANCE
    INSTANCE=$1
    COMMAND_OUTPUT=`cat /etc/group | grep "ckan${INSTANCE}:"`
    if ! [[ "$COMMAND_OUTPUT" =~ "ckan${INSTANCE}:" ]] ; then
        echo "Creating the 'ckan${INSTANCE}' group ..." 
        sudo groupadd --system "ckan${INSTANCE}"
        echo "Adding the okfn user to it..."
        sudo usermod --append --groups "ckan${INSTANCE}" okfn
    fi
    COMMAND_OUTPUT=`cat /etc/passwd | grep "ckan${INSTANCE}:"`
    if ! [[ "$COMMAND_OUTPUT" =~ "ckan${INSTANCE}:" ]] ; then
        echo "Creating the 'ckan${INSTANCE}' user ..." 
        sudo useradd --system  --gid "ckan${INSTANCE}" --home $CKAN_LIB/${INSTANCE} -M  --shell /usr/sbin/nologin ckan${INSTANCE}
    fi
}

ckan_make_ckan_directories () {
    local INSTANCE
    if [ "X$1" = "X" ] ; then
        echo "ERROR: call the function make_ckan_directories with an INSTANCE name, e.g." 
        echo "       std"
        exit 1
    else
        INSTANCE=$1
        mkdir -p -m 0755 $CKAN_ETC/${INSTANCE}
        mkdir -p -m 0750 $CKAN_LIB/${INSTANCE}{,/static}
        mkdir -p -m 0770 /var/{backup,log}/ckan/${INSTANCE} $CKAN_LIB/${INSTANCE}/{data,sstore,static/dump}
        sudo chown ckan${INSTANCE}:ckan${INSTANCE} $CKAN_ETC/${INSTANCE}
        sudo chown apache:ckan${INSTANCE} /var/{backup,log}/ckan/${INSTANCE} $CKAN_LIB/${INSTANCE} $CKAN_LIB/${INSTANCE}/{data,sstore,static/dump}
        sudo chmod g+w /var/log/ckan/${INSTANCE} $CKAN_LIB/${INSTANCE}/{data,sstore,static/dump}
    fi
}

ckan_create_who_ini () {
    local INSTANCE
    if [ "X$1" = "X" ] ; then
        echo "ERROR: call the function create_who_ini function with an INSTANCE name, e.g." 
        echo "       std"
        exit 1
    else
        INSTANCE=$1
        local PYENV=$CKAN_LIB/${INSTANCE}/pyenv
        if ! [ -f $CKAN_ETC/${INSTANCE}/who.ini ] ; then
            cp -n $PYENV/src/ckan/ckan/config/who.ini $CKAN_ETC/${INSTANCE}/who.ini
            sed -e "s,%(here)s,$CKAN_LIB/${INSTANCE}," \
                -i $CKAN_ETC/${INSTANCE}/who.ini
            chown ckan${INSTANCE}:ckan${INSTANCE} $CKAN_ETC/${INSTANCE}/who.ini
        fi
    fi
}

ckan_create_config_file () {
    local INSTANCE password LOCAL_DB
    if [ "X$1" = "X" ] || [ "X$2" = "X" ] ; then
        echo "ERROR: call the function create_config_file function with an INSTANCE name, and a password for postgresql e.g."
        echo " std 1U923hjkh8"
        exit 1
    else
        INSTANCE=$1
        password=$2
        LOCAL_DB=$3
        # Create an install settings file if it doesn't exist
        if [ -f $CKAN_ETC/${INSTANCE}/${INSTANCE}.ini ] ; then
            mv $CKAN_ETC/${INSTANCE}/${INSTANCE}.ini "$CKAN_ETC/${INSTANCE}/${INSTANCE}.ini.`date +%F_%T`.bak"
        fi
        echo "Paster Used: `which paster`"
        paster make-config ckan $CKAN_ETC/${INSTANCE}/${INSTANCE}.ini

        if [[ ( "$LOCAL_DB" == "yes" ) ]]
        then
            sed -e "s,^\(sqlalchemy.url\)[ =].*,\1 = postgresql://${INSTANCE}:${password}@localhost/${INSTANCE}," \
                -i $CKAN_ETC/${INSTANCE}/${INSTANCE}.ini
        fi
        sed -e "s,^\(email_to\)[ =].*,\1 = root," \
            -e "s,^\(error_email_from\)[ =].*,\1 = ckan-${INSTANCE}@`hostname`," \
            -e "s,# ckan\.site_id = ckan.net,ckan.site_id = ${INSTANCE}," \
            -e "s,^\(cache_dir\)[ =].*,\1 = $CKAN_LIB/${INSTANCE}/data," \
            -e "s,^\(who\.config_file\)[ =].*,\1 = $CKAN_ETC/${INSTANCE}/who.ini," \
            -e "s,\"ckan\.log\",\"/var/log/ckan/${INSTANCE}/${INSTANCE}.log\"," \
            -e "s,#solr_url = http://127.0.0.1:8983/solr,solr_url = http://127.0.0.1:8983/solr," \
            -i $CKAN_ETC/${INSTANCE}/${INSTANCE}.ini
        sudo chown ckan${INSTANCE}:ckan${INSTANCE} $CKAN_ETC/${INSTANCE}/${INSTANCE}.ini
    fi
}

ckan_add_or_replace_database_user () {
    local INSTANCE password
    if [ "X$1" = "X" ] || [ "X$2" = "X" ] ; then
        echo "ERROR: call the function ckan_add_or_replace_database_user function with an INSTANCE name, and a password for postgresql e.g." 
        echo "       std 1U923hjkh8"
        echo "       You can generate a password like this: "
        echo "           < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c10"
        exit 1
    else
        INSTANCE=$1
        password=$2
        COMMAND_OUTPUT=`sudo -u postgres -i psql -c "SELECT 'True' FROM pg_user WHERE usename='${INSTANCE}'"`
        if ! [[ "$COMMAND_OUTPUT" =~ True ]] ; then
            echo "Creating the ${INSTANCE} user ..."
            sudo -u postgres -i createuser -S -D -R ${INSTANCE}
            # sudo -u postgres -i psql -c "CREATE USER \"${INSTANCE}\" WITH PASSWORD '${password}'"
        else
            echo "Setting the ${INSTANCE} user password ..."
            sudo -u postgres -i psql -c "ALTER USER \"${INSTANCE}\" WITH PASSWORD '${password}'"
        fi
    fi
}

ckan_ensure_db_exists () {
    local INSTANCE
    if [ "X$1" = "X" ] ; then
        echo "ERROR: call the function ensure_db_exists function with an INSTANCE name, e.g." 
        echo "       std"
        exit 1
    else
        INSTANCE=$1
        COMMAND_OUTPUT=`sudo -u postgres -i psql -c "select datname from pg_database where datname='$INSTANCE'"`
        if ! [[ "$COMMAND_OUTPUT" =~ ${INSTANCE} ]] ; then
            echo "Creating the database ..."
            sudo -u postgres -i createdb -O ${INSTANCE} ${INSTANCE}
            ## paster --plugin=ckan db init --config=$CKAN_ETC/${INSTANCE}/${INSTANCE}.ini
        fi
    fi
}

ckan_create_wsgi_handler () {
    local INSTANCE
    if [ "X$1" = "X" ] ; then
        echo "ERROR: call the function create_wsgi_handler function with an INSTANCE name, e.g." 
        echo "       std"
        exit 1
    else
        INSTANCE=$1

        mkdir -p /var/www/drupal

        if [ ! -f "$CKAN_LIB/${INSTANCE}/wsgi.py" ]
        then
            ## echo "Pip used: `which pip`"
            ## sudo chown -R ckan${INSTANCE}:ckan${INSTANCE} $CKAN_LIB/${INSTANCE}/pyenv
            ## sudo -u ckan${INSTANCE} virtualenv --setuptools $CKAN_LIB/${INSTANCE}/pyenv
            ## echo "Attempting to install 'pip' 1.0 from pypi.python.org into pyenv to be used for extensions ..."
            ## sudo -u ckan${INSTANCE} $CKAN_LIB/${INSTANCE}/pyenv/bin/easy_install --upgrade "pip>=1.0" "pip<=1.0.99"
            ## echo "done."
            ## echo "Attempting to install 'paster' pypi.python.org into pyenv ..."
            ## sudo -u ckan${INSTANCE} $CKAN_LIB/${INSTANCE}/pyenv/bin/easy_install --ignore-installed "pastescript"
            ## echo "done."
            cat <<- EOF > $CKAN_LIB/${INSTANCE}/packaging_version.txt
				1.7
			EOF
            cat <<- EOF > $CKAN_LIB/${INSTANCE}/wsgi.py
				import os
				instance_dir = '$CKAN_LIB/${INSTANCE}'
				config_dir = '$CKAN_ETC/${INSTANCE}'
				config_file = '${INSTANCE}.ini'
				pyenv_bin_dir = os.path.join(instance_dir, 'pyenv', 'bin')
				activate_this = os.path.join(pyenv_bin_dir, 'activate_this.py')
				execfile(activate_this, dict(__file__=activate_this))
				# this is werid but without importing ckanext first import of paste.deploy will fail
				#import ckanext
				config_filepath = os.path.join(config_dir, config_file)
				if not os.path.exists(config_filepath):
				    raise Exception('No such file %r'%config_filepath)
				from paste.deploy import loadapp
				from paste.script.util.logging_config import fileConfig
				fileConfig(config_filepath)
				application = loadapp('config:%s' % config_filepath)
				from apachemiddleware import MaintenanceResponse
				application = MaintenanceResponse(application)
			EOF
        sudo chmod +x $CKAN_LIB/${INSTANCE}/wsgi.py
        fi
   fi
}

ckan_overwrite_apache_config () {
    local INSTANCE ServerName
    if [ "X$1" = "X" ] ; then
        echo "ERROR: call the function overwrite_apache_config function with an INSTANCE name, and the server name e.g." 
        echo "       std uat.ec.ckan.org"
        exit 1
    else
        INSTANCE=$1
        ServerName=$2

        echo "Creating auth.py file instance ${INSTANCE}"
        cat << EOF > $CKAN_LIB/${INSTANCE}/auth.py

def check_password(environ, user, password):
    if user == 'ec':
        return password == 'ecportal'
    return None
EOF
        
        echo "Creating httpd configuration file for instance ${INSTANCE}"
        cat <<- EOF > /etc/httpd/conf.d/${INSTANCE}.conf

			<VirtualHost *:8008>
			
			    DocumentRoot /var/www/drupal
			    ServerName ${ServerName}
			    ServerAlias ${ServerName} localhost
			    DirectoryIndex index.phtml index.html index.php index.htm
			
			    RewriteEngine on
			    RewriteRule ^/open-data/(..)/data($|/(.*))$ /open-data/data/\$1/\$3 [L,QSA,PT]
			
			#    <Directory />
			#        Options Indexes FollowSymLinks MultiViews
			#        AllowOverride All
			#        Order allow,deny
			#        Allow from all
			#    </Directory>
			
			#    <Directory /home/okfn/ecportal/>
			#       allow from all
			#       AuthType Basic
			#       AuthName "CKAN"
			#       AuthBasicProvider wsgi
			#       WSGIAuthUserScript /home/okfn/ecportal/auth.py
			#       Require valid-user 
			#    </Directory>
			
			
			    <Location />
			       allow from all
			       AuthType Basic
			       AuthName "ODP"
			       AuthBasicProvider wsgi
			       WSGIAuthUserScript $CKAN_LIB/${INSTANCE}/auth.py
			       Require valid-user
			    </Location>

          # Open up the action and data apis as they are required
          # for the ckanext-qa and ckanext-datastorer extensions,
          # both of which don't allow access to resources requiring
          # authentication.
          <Location /open-data/data/api/action>
            allow from all
            Order allow,deny
            Satisfy Any
          </Location>

          <Location /open-data/data/api/data>
            allow from all
            Order allow,deny
            Satisfy Any
          </Location>
			
			    <Directory $CKAN_LIB/${INSTANCE}/static>
			        allow from all
			    </Directory>
			
			    Alias /open-data/data/dump $CKAN_LIB/${INSTANCE}/static/dump
			
			    # Disable the mod_python handler for static files
			    <Location /open-data/dump>
			        SetHandler None
			        Options +Indexes
			    </Location>
			
			    # this is our app
			    WSGIScriptAlias /open-data/data $CKAN_LIB/${INSTANCE}/wsgi.py
			    WSGIDaemonProcess ${INSTANCE} display-name=${INSTANCE} processes=2 threads=10
			    WSGIProcessGroup ${INSTANCE}
			
			    # pass authorization info on (needed for rest api)
			    WSGIPassAuthorization On
			
			    # Added by 10F
			    <Directory /var/www/drupal>
			        Options Indexes FollowSymLinks MultiViews
			        AllowOverride All
			        Order allow,deny
			        allow from all
			    </Directory>
			    RedirectMatch ^/$ /open-data/
			#    Alias /open-data /var/www/drupal
			
			    # Added by InfAI
			    <Directory /home/michaelm/repositories/sources/visualizations/cubeVizWidget/cubeViz>
			        Options Indexes FollowSymLinks MultiViews
			        AllowOverride All
			        Order allow,deny
			        Allow from all
			    </Directory>
			    Alias /open-data/apps/cubeviz /home/michaelm/repositories/sources/visualizations/cubeVizWidget/cubeViz
			    Alias /open-data/apps/spatial-browser /home/clauss/Repositories/SpatialSemanticBrowsingWidgets
			
			    <Proxy *>
			            Order allow,deny
			            allow from all
			    </Proxy>
			
			    ProxyPass /open-data/sparql http://localhost:8894/sparql retry=0
			    ProxyPassReverse /open-data/sparql http://localhost:8894/sparql
			
			    # Virtuoso 6.1.5 endpoint
			    ProxyPass /open-data/sparql615 http://localhost:8893/sparql retry=0
			    ProxyPassReverse /open-data/sparql615 http://localhost:8893/sparql
			
			
			    ProxyPass /open-data/conductor http://localhost:8892/conductor retry=0
			    ProxyPassReverse /open-data/conductor http://localhost:8892/conductor
			
			    ErrorLog /var/log/httpd/${INSTANCE}.error.log
			    CustomLog /var/log/httpd/${INSTANCE}.custom.log combined
			
			#    RewriteEngine on
			#    RewriteRule ^open-data/(..)/data/(.*) /open-data/data/\$1/\$2 [L,QSA,PT]
			</VirtualHost>

		EOF
    fi
}
