===========
Maintenance
===========

This documents some common maintenance tasks and the layout of the
applications on the server.

======================
Layout Of Installation
======================

This documents what's installed, how and where.

Briefly, the following services are installed:

  * Solr (served by tomcat6)
  * Postgresql
  * Elasticsearch

  * nginx
  * apache2
  * supervisord
  * CKAN

And the application as a whole is installed in
`/applications/ecodp/users/ecodp/`, with each of the above services having an
entry as a *product* within the application structure. Eg -
`/applications/ecodp/users/ecodp/nginx`.  This base directory is refered to as
`$CKAN_APPLICATION` in the install scripts: ::

  CKAN_APPLICATION=/applications/ecodp/users/ecodp

Solr (1.4.1)
============

::

  SOLR_PRODUCT=$CKAN_APPLICATION/solr
  TOMCAT_PRODUCT=$CKAN_APPLICATION/tomcat

Tomcat is a package install, with its `lib` and `etc` soft-linked to from
within the `$TOMCAT_PRODUCT` directory.

Solr is installed manually by dropping the approparite ``.war`` file into
tomcat's webapps directory.  It's data directory is `$SOLR_PRODUCT/data` and
the location of it's schema file etc is `$SOLR_PRODUCT/solr`.

Tomcat is run under the ``tomcat`` user.

Postgres
========

::

  POSTGRES_PRODUCT=$CKAN_APPLICATION/postgres

Postgresql is a package install with it's `/var/lib/pgsql` directory being
linked to from `$POSTGRES_PRODUCT/pgsql`.  This contains the data directory as
well as configuration files.

Postgres is run under the ``postgres`` user.



ElasticSearch
=============

::

  ES_PRODUCT=$CKAN_APPLICATION/elasticsearch

This is a manual installation of 0.19.4 distribution of elasticsearch.  The
distribution itself is simply dropped into `$ES_PRODUCT`, and is
self-contained.  The only other addition is an init.d script is placed in
`/etc/init.d/elasticsearch` (and linked to from
`$CKAN_APPLICATION/init.d/elasticsearch`) which as then added to run-levels 3,4
and 5 for starting up at boot time.

One other aspect of the installation is that elastic search runs under its own
user, `elasticsearch`, which has had the number of file descriptors made
available to it increased to 32000.  As per the production-deployment
instructions for elasticsearch.

Elasticsearch is run under the ``elasticsearch`` user.

Nginx
=====

::

  NGINX_PRODUCT=$CKAN_APPLICATION/nginx

This is a package install.  However, the package isn't available in the
standard repositories.  As such the rpm is made available through nginx's own
maintained repositories.  Once installed, it's configuration files are linked
to from `$NGINX_PRODUCT/etc`.

Nginx is set up to forward `/` urls to apache.  And to proxy
`/elastic/` urls to elasticsearch.

Nginx's master process is running under ``root``.  This appears to be standard
in order that nginx can open privelaged ports without having to "tinker" with
permissions.  It should be possible to grant those permissions on the nginx
executable using ``setcap``.

Nginx's worker processes all run under the ``nginx`` user.

Apache
======

This is just a standard package installation.  Configuration files are found in
`/etc/httpd/`.

Like Nginx_, Apache's master process is run as ``root``.
Apache's worker processes are run as ``apache``.

Supervisord
===========

::

  SUPERVISOR_PRODUCT=$CKAN_APPLICATION/supervisor

This is installed into the python virtualenvironment associated with the CKAN
instance.  It's configuration files; log files and run files (.pid and .sock
files) are all found under `$SUPERVISOR_PRODUCT/{var/log, etc, var/run}`

Supervisor is run under the ``ecodp`` user.
The monitored celery tasks are run under ``ecodp`` as well.

CKAN
====

::

  CKAN_APPLICATION=/applications/ecodp/users/ecodp
  CKAN_VERSION="release-v1.7.1-ecportal"
  CKAN_INSTALL_DIR=$CKAN_APPLICATION/ckan/lib
  CKAN_LIB=$CKAN_INSTALL_DIR
  CKAN_ETC=$CKAN_APPLICATION/ckan/etc
  CKAN_HOME="$CKAN_INSTALL_DIR/$CKAN_INSTANCE"
  PYENV="$CKAN_HOME/pyenv"

CKAN itself is a source installation, with a python environment for *each* CKAN
instance.  As per usual, each ckan extenstion is also a source install.

========================
Common Maintenance Tasks
========================


Upgrading CKAN
==============

To upgrade CKAN's source installation, follow these steps: ::

  # Assuming initial config settings:
  CKAN_INSTANCE=ecodp
  CKAN_VERSION=release-v1.7.1-ecportal

  # Working in the CKAN source directory
  cd /applications/ecodp/users/ecodp/ckan/lib/${CKAN_INSTANCE}/pyenv/src/ckan

  # Update the source code
  git fetch
  git merge origin/$CKAN_VERSION

  # Activate the python virtualenv
  source /applications/ecodp/users/ecodp/ckan/lib/${CKAN_INSTANCE}/pyenv/bin/activate

  # Run any database migrations
  paster db upgrade -c /applications/ecodp/users/ecodp/ckan/etc/%{CKAN_INSTANCE}/%{CKAN_INSTANCE}.ini

  # Update the solr schema (if necessary)
  cp /applications/ecodp/users/ecodp/ckan/lib/${CKAN_INSTANCE}/pyenv/src/ckan/ckanext/multilingual/solr \
     /applications/ecodp/users/ecodp/solr/solr/conf
  /applications/ecodp/users/ecodp/init.d/tomcat6 restart

  # Restart apache
  /applications/ecodp/users/ecodp/init.d/httpd restart

If the solr schema has been upgrade, then you'll need to

Upgrading CKAN's extensions
===========================

Each of CKAN's extensions are source installations too, which means any one of
them can be upgraded following a similar procedure to that above: ::

  # Assuming initial config settings:
  CKAN_INSTANCE=ecodp

  # The extension we wish to upgrade, change as appropriate:
  CKAN_EXTENSION=ckanext-qa

  # Working in the CKAN source directory
  cd /applications/ecodp/users/ecodp/ckan/lib/${CKAN_INSTANCE}/pyenv/src/${CKAN_EXTENSION}

  # Update the source code
  git fetch
  git merge origin master

  # Restart apache
  /applications/ecodp/users/ecodp/init.d/httpd restart

Rebuilding Search Index
=======================

The search index is rebuilt using a paster command: ::

  # Assuming initial config settings:
  CKAN_INSTANCE=ecodp

  # Activate the python virtualenv
  source /applications/ecodp/users/ecodp/ckan/lib/${CKAN_INSTANCE}/pyenv/bin/activate

  # Working in the CKAN source directory
  cd /applications/ecodp/users/ecodp/ckan/lib/${CKAN_INSTANCE}/pyenv/src/ckan

  # Run the paster command
  paster search-index rebuild -c /applications/ecodp/users/ecodp/ckan/etc/%{CKAN_INSTANCE}/%{CKAN_INSTANCE}.ini

Restarting services
===================

There's a link to each service's init.d script in
`/applications/ecodp/users/ecodp/init.d`.  Each one accepts `start`, `stop`,
`status` and `restart`.  For example: ::

  /applications/ecodp/users/ecodp/init.d/httpd restart

Changing the HTTP Auth User
===========================

The HTTP Auth username/password is currently hardcoded into the file: ::

  /applications/ecodp/users/ecodp/ckan/lib/ecodp/auth.py

To change the username/password, edit this file and then restart apache (below)

The authentication can be removed by editing apache configuration: ::

	/etc/httpd/conf.d/ecodp.conf

The whole of this block can be removed or commented out:  ::
 
	#<Location />
	#		allow from all
	#		AuthType Basic
	#		AuthName "ODP"
	#		AuthBasicProvider wsgi
	#		WSGIAuthUserScript /applications/ecodp/users/ecodp/ckan/lib/ecodp/auth.py
	#		Require valid-user
	#</Location>

After that, apache needs to be restarted: ::

	service httpd restart


Adding CKAN Users
=================

Normal CKAN users and system administators can be added via the
``paster user add`` and ``paster sysadmin add`` commands respectively.

For example, to create a new sysadmin called ``admin``: ::

  # Assuming initial config settings:
  CKAN_INSTANCE=ecodp

  # Activate the python virtualenv
  source /applications/ecodp/users/ecodp/ckan/lib/${CKAN_INSTANCE}/pyenv/bin/activate

  # Working in the CKAN or an extension directory
  cd /applications/ecodp/users/ecodp/ckan/lib/${CKAN_INSTANCE}/pyenv/src/ckan

  # Run the paster command, referencing the .ini file
  paster sysadmin add admin -c /applications/ecodp/users/ecodp/ckan/etc/%{CKAN_INSTANCE}/%{CKAN_INSTANCE}.ini

More information on CKAN user management can be found at:
http://docs.ckan.org/en/latest/paster.html#user-create-and-manage-users

Running QA tasks
================

The QA tasks can be triggered by running a paster command: ::

  # Assuming initial config settings:
  CKAN_INSTANCE=ecodp

  # Activate the python virtualenv
  source /applications/ecodp/users/ecodp/ckan/lib/${CKAN_INSTANCE}/pyenv/bin/activate

  # Working in the qa source directory
  cd /applications/ecodp/users/ecodp/ckan/lib/${CKAN_INSTANCE}/pyenv/src/ckanext-qa

  # Run the paster command
  paster qa update --config /applications/ecodp/users/ecodp/ckan/etc/%{CKAN_INSTANCE}/%{CKAN_INSTANCE}.ini

Running paster commands in general
==================================

In general, running a paster command consists of: ::

  # Assuming initial config settings:
  CKAN_INSTANCE=ecodp

  # Activate the python virtualenv
  source /applications/ecodp/users/ecodp/ckan/lib/${CKAN_INSTANCE}/pyenv/bin/activate

  # Working in the CKAN or an extension directory
  cd /applications/ecodp/users/ecodp/ckan/lib/${CKAN_INSTANCE}/pyenv/src/ckan

  # Run the paster command, referencing the .ini file
  paster {commands} -c /applications/ecodp/users/ecodp/ckan/etc/%{CKAN_INSTANCE}/%{CKAN_INSTANCE}.ini


=====================
Backup and Restore DB
=====================

On the backend machine run the following command as ``root``::

  su postgres -c 'pg_dump ecodp > /tmp/ecodp.dump'

This will dump the ecodp database /tmp directory. It is recommended to use
the /tmp directory as the postgres user has very little rights and has not
got access to most directories.

As you are acting as postgres user you do not need to enter a password.

The restore the database run.::

  su postgres -c 'psql -d ecodp -f /tmp/ecodp.dump'

This will restore the dump file to the ecodp database.  This database
needs to be empty and must exist. This will be the case if you have just
run the backend services script.

*If* a mistake is made and you want to refresh the data on an already
populated database then this command can be run from the *frontend* server.::

  # Run the paster command, referencing the .ini file
  paster db clean -c /applications/ecodp/users/ecodp/ckan/etc/%{CKAN_INSTANCE}/%{CKAN_INSTANCE}.ini

Once run the command the restore command can be run again.

CKAN URL TESTS
================

The following in ckan urls should be tested to see if they are
working.  These should be off /data

/
/dataset
/dataset/new
/organization
organization/new
organization/estat
/user/register
/user

A test dataset should be made in /dataset/new with name say "test1".
Once that is made the following should be checked.

/dataset?q=test1  (search returns the dataset)

/dataset/test1
/dataset/editresources/test1  (a resource should be made)
/dataset/edit/test1  (edits should be made)
/dataset/history/test1  (see if edits in history)
/dataset/test1.rdf
/dataset/edit/test1 (dataset should be deleted in bottom tab)

/dataset?q=test1  (search no longer returns dataset)
