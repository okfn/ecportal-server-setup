===========================
EC Portal CKAN Installation
===========================

This documents the steps to install CKAN on EC portal's machines.  The
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
    Extract the scripts folder to a working directory; eg. `/tmp/scripts`

 #. From the working directory, edit the `config` file.

    i)   The `CKAN_DATABASE_PASSWORD` setting needs setting to a randomly
         chosen password that will be used for CKAN user setup for postgresql.

    ii)  The `CKAN_BACKEND_SERVER` needs to be set to the IP address that the
         backend services will be installed on.  This is used to ensure that
         the frontend services are configured correctly.  If you are installing
         everything on the same machine, then leave it as `0.0.0.0`.

    iii) The `CKAN_INSTANCE` can be anything; `ecportal` is a sensible choice.

    iv)  `CKAN_DOMAIN` should be the domain name serving CKAN.

    v)   All other options should be left as they are.

Repositories
------------

These deployment scripts have been tested on CentOS 6.2 and a trial version of
RHEL 6.2.  As such, it may be the case that some packages we assume that are
available in the yum repositories, are not available in the enterprise
repositories.  To this end, there are two scripts available for adding
additional repositories: `configure_centos_repositories.sh` and
`configure_epel_repositories.sh`.  When testing on a trial version of RHEL 6.2
we found that only adding the epel repository was not enough to satisfy all the
dependencies.  (At least the `git` package was missing; there may be more).  So
**we recommend you attempt the installation without adding any extra
repositories; and if that fails then add the centos repository**.  If you wish
to add the epel repository as well, we've provided a script to do so, but it's
optional.

To use the provided repository scripts: ::

  # within the working directory, eg. /tmp/scripts
  source ./configure_centos_repositories.sh
  configure_centos_repositories

Or, for the epel repository: ::

  # within the working directory, eg. /tmp/scripts
  source ./configure_epel_repositories.sh
  configure_epel_repositories


Backend Services Installation
=============================

 1. First, ensure you have followed the Preliminary steps above.

 2. From within `/tmp/scripts`, run the following **as root**: ::

      bash ./install_backend_services.sh | tee ./backend_install.log

 3. This will prompt you for a password for the `okfn` user.  Other thatn that
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

 2. From within `/tmp/scripts`, run the following **as root**: ::

      bash ./install_frontend_services.sh | tee frontend_install.log

 3. This will prompt you for a password for the `okfn` user if you are running
    this on a separate machine to the backend.

This will install and configure nginx, apache and CKAN.

Overview of frontend installation
---------------------------------

The frontend installation is broken into 2 parts: installing nginx, and installing CKAN and apache:

.. include:: scripts/install_frontend_services.sh
   :code: bash

(TODO: move apache installation/configuration into separate file)

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

  #. Applies two patches to the CKAN installation.  This is because they are
     specific to ecportal's deployment:

     .. include:: scripts/ckan.patch
        :code: diff
     
     .. include:: scripts/elastic_search_redirect.patch
        :code: diff

  #. Runs some commands to load initial data for the installation, ie - the
     ecportal vocabs.

  #. Installs and configures celery to be monitored by supervisord.

  #. Configures the file-upload storage.

  #. Ensures selinux permissions are correct for allowing apache to:

     i)   Load the necessary python modules in the virtaulenv.
     ii)  Make connections to the databases.

