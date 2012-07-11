===========================
EC Portal CKAN Installation
===========================

This documents the steps to install CKAN on EC ODP machines. The
installation is broken into two parts: the back-end and the front-end boxes.
It *is* possible to install both set of services on a single machine.

Preliminaries
=============

**NOTE**: These scripts assume you are running as **root**.

If you are installing both backend services and frontend service on the same
machine, then you only need to setup the following once.  If installing on two
separate machines, then the following preliminary steps need to be carried out
on each machine, with the same config settings each time.

 1. You need a copy of these instructions, and the scripts that go with them.
    Extract the scripts folder to a working directory; eg. `/tmp/scripts`, and the
    rpms and downloads folders to a working directory at the same level as the scripts,
    eg `/tmp/rpms` and `/tmp/downloads`.

 #. From the working directory, edit the `config` file.

    i)   The `CKAN_DATABASE_PASSWORD` setting needs setting to a randomly
         chosen password that will be used for CKAN user setup for postgresql.

    ii)  The `CKAN_BACKEND_SERVER` needs to be set to the IP address that the
         backend services will be installed on.  This is used to ensure that
         the frontend services are configured correctly.  If you are installing
         everything on the same machine, then leave it as `0.0.0.0`.

    iii) `CKAN_DOMAIN` should be the domain name serving CKAN.

    iv)  All other options should be left as they are.

Backend Services Installation
=============================

 1. First, ensure you have followed the Preliminary steps above.

 #. From within `/tmp/downloads`, download the following CKAN dependencies: ::

      yum install wget # if not already installed

      wget http://s031.okserver.org/ecportal-downloads/apache-solr-1.4.1.tgz
      wget http://s031.okserver.org/ecportal-downloads/solr_schema.tar.gz
      wget http://s031.okserver.org/ecportal-downloads/elasticsearch-0.19.4.tar.gz

 #. From within `/tmp/scripts`, run the following **as root**: ::

      bash ./install_backend_services.sh | tee ./backend_install.log

 #. This will prompt you for a password for the `ecportal` user. Other that that
    it should run without further prompts.

This will install solr, postgres and elasticsearch.

It **will not** touch itables configuration, so you'll need to ensure that
the following ports are available to the frontend machine on your network:

 solr (tomcat) : 8983
 postgresql    : 5432
 elasticsearch : 9200

Overview of backend installation
--------------------------------

The steps for each service are in separate files, `solr.sh`, `postgresql.sh`
and `elasticsearch.sh`.  It should be obvious from the
`install_backend_services.sh` script how to run each of these manually in
turn if wished:

.. include:: scripts/install_backend_services.sh
   :code: bash

And each script is documented in-line with explanations of what's being
installed/configured.  They all require the environment variables set in
`source config`.

Frontend Services Installation
==============================

 1. First, ensure you have followed the preliminary steps above.

 #. From within `/tmp/rpms`, download the packaged-up python dependencies: ::

      yum install wget # if not already installed

      wget http://s031.okserver.org/ecportal-rpms/nginx-1.2.2-1.el6.ngx.x86_64.rpm
      wget http://s031.okserver.org/ecportal-rpms/ecportal-python-virtual-environment-1.7.1-1.x86_64.rpm

    The latter is an rpm of the python virtual environment, and is used to expediate
    the install process.

 #. From within `/tmp/scripts`, run the following **as root**: ::

      bash ./install_frontend_services.sh | tee frontend_install.log

 #. This will prompt you for a password for the `ecportal` user if you are running
    this on a separate machine to the backend.

This will install and configure nginx, apache and CKAN.

Overview of frontend installation
---------------------------------

The frontend installation is broken into 2 parts: installing nginx, and
installing CKAN and apache:

.. include:: scripts/install_frontend_services.sh
   :code: bash

The nginx part is quite simple, and should be easy to follow.

The CKAN installation is a bit more complicated.  The script is peppered with
comments as to what's being run, but roughly, it does the following:

  1. Installs and configures apache2

  #. Creates a new python virtualenv.

  #. Installs CKAN and it's python dependencies into that virtual env.

  #. Creates a new ckan instance, running in the new virtual env.

  #. Installs the ecportal extension, and it's dependant ckan extensions (qa,
     archiver and datastorer).

  #. Modifies the generated CKAN configuration file with settings particular
     for ecportal, including the correct connection strings for solr and postgres.

  #. Runs some commands to load initial data for the installation, ie - the
     ecportal vocabs.

  #. Installs and configures celery to be monitored by supervisord.

  #. Configures the file-upload storage.

  #. Ensures selinux permissions are correct for allowing apache to:

     i)   Load the necessary python modules in the virtaulenv.
     ii)  Make connections to the databases.


Checking that CKAN is installed
===============================

Your CKAN instance should now be available at
http://localhost/open-data/data/

To verify, go to this address in your browser or from the command line, run::

    curl --user <http auth user name>:<http auth password> http://localhost/open-data/data/

The CKAN homepage should be displayed.
