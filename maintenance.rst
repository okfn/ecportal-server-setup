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
`/applications/ckan/users/system/`, with each of the above services having an
entry as a *product* within the application structure. Eg -
`/applications/ckan/users/system/nginx`.  This base directory is refered to as
`$CKAN_APPLICATION` in the install scripts: ::

  CKAN_APPLICATION=/applications/ckan/users/system

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

Postgres
========

::

  POSTGRES_PRODUCT=$CKAN_APPLICATION/postgres

Postgresql is a package install with it's `/var/lib/pgsql` directory being
linked to from `$POSTGRES_PRODUCT/pgsql`.  This contains the data directory as
well as configuration files.

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

Nginx
=====

::

  NGINX_PRODUCT=$CKAN_APPLICATION/nginx

This is a package install.  However, the package isn't available in the
standard repositories.  As such the rpm is made available through nginx's own
maintained repositories.  Once installed, it's configuration files are linked
to from `$NGINX_PRODUCT/etc`.

Nginx is set up to forward `/open-data/` urls to apache.  And to proxy
`/open-data/elastic/` urls to elasticsearch.

Apache
======

This is just a standard package installation.  Configuration files are found in
`/etc/httpd/`.

Supervisord
===========

::

  SUPERVISOR_PRODUCT=$CKAN_APPLICATION/supervisor

This is installed into the python virtualenvironment associated with the CKAN
instance.  It's configuration files; log files and run files (.pid and .sock
files) are all found under `$SUPERVISOR_PRODUCT/{var/log, etc, var/run}`

CKAN
====

::

  CKAN_APPLICATION=/applications/ckan/users/system
  CKAN_VERSION="release-v1.7"
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
  CKAN_INSTANCE=ecportal
  CKAN_VERSION=release-v1.7

  # Working in the CKAN source directory
  cd /applications/ckan/users/system/ckan/lib/${CKAN_INSTANCE}/pyenv/src/ckan

  # Update the source code
  git fetch
  git merge origin/$CKAN_VERSION

  # Activate the python virtualenv
  source /applications/ckan/users/system/ckan/lib/${CKAN_INSTANCE}/pyenv/bin/activate

  # Run any database migrations
  paster db upgrade -c /applications/ckan/users/system/ckan/etc/%{CKAN_INSTANCE}/%{CKAN_INSTANCE}.ini

  # Update the solr schema (if necessary)
  cp /applications/ckan/users/system/ckan/lib/${CKAN_INSTANCE}/pyenv/src/ckan/ckanext/multilingual/solr \
     /applications/ckan/users/system/solr/solr/conf
  /applications/ckan/users/system/init.d/tomcat6 restart

  # Restart apache
  /applications/ckan/users/system/init.d/httpd restart

If the solr schema has been upgrade, then you'll need to 

Upgrading CKAN's extensions
===========================

Each of CKAN's extensions are source installations too, which means any one of
them can be upgraded following a similar procedure to that above: ::

  # Assuming initial config settings:
  CKAN_INSTANCE=ecportal

  # The extension we wish to upgrade, change as appropriate:
  CKAN_EXTENSION=ckanext-qa

  # Working in the CKAN source directory
  cd/applications/ckan/users/system/ckan/lib/${CKAN_INSTANCE}/pyenv/src/${CKAN_EXTENSION}

  # Update the source code
  git fetch
  git merge origin master

  # Restart apache
  /applications/ckan/users/system/init.d/httpd restart

Rebuilding Search Index
=======================

The search index is rebuilt using a paster command: ::

  # Assuming initial config settings:
  CKAN_INSTANCE=ecportal

  # Activate the python virtualenv
  source /applications/ckan/users/system/ckan/lib/${CKAN_INSTANCE}/pyenv/bin/activate

  # Working in the CKAN source directory
  cd /applications/ckan/users/system/ckan/lib/${CKAN_INSTANCE}/pyenv/src/ckan

  # Run the paster command
  paster search-index rebuild -c /applications/ckan/users/system/ckan/etc/%{CKAN_INSTANCE}/%{CKAN_INSTANCE}.ini

Restarting services
===================

There's a link to each service's init.d script in
`/applications/ckan/users/system/init.d`.  Each one accepts `start`, `stop`,
`status` and `restart`.  For example: ::

  /applications/ckan/users/system/init.d/httpd restart

Running QA tasks
================

The QA tasks can be triggered by running a paster command: ::
  
  # Assuming initial config settings:
  CKAN_INSTANCE=ecportal

  # Activate the python virtualenv
  source /applications/ckan/users/system/ckan/lib/${CKAN_INSTANCE}/pyenv/bin/activate

  # Working in the qa source directory
  cd /applications/ckan/users/system/ckan/lib/${CKAN_INSTANCE}/pyenv/src/ckanext-qa

  # Run the paster command
  paster qa update --config /applications/ckan/users/system/ckan/etc/%{CKAN_INSTANCE}/%{CKAN_INSTANCE}.ini

Running paster commands in general
==================================

In general, running a paster command consists of: ::

  # Assuming initial config settings:
  CKAN_INSTANCE=ecportal

  # Activate the python virtualenv
  source /applications/ckan/users/system/ckan/lib/${CKAN_INSTANCE}/pyenv/bin/activate

  # Working in the CKAN or an extension directory
  cd /applications/ckan/users/system/ckan/lib/${CKAN_INSTANCE}/pyenv/src/ckan

  # Run the paster command, referencing the .ini file
  paster {commands} -c /applications/ckan/users/system/ckan/etc/%{CKAN_INSTANCE}/%{CKAN_INSTANCE}.ini


