===========================
EC Portal CKAN Installation
===========================

This documents the steps to install CKAN on EC ODP servers. The
installation is broken into two parts: the back-end and the front-end.
It *is* possible to install both set of services on a single machine.

Preliminaries
=============

**NOTE**: These scripts assume you are running as **root**.

The following preliminary steps need to be carried out on **both** the
front-end and the back-end machines; with the same configuration settings each
time.

 1. You need a copy of these instructions, and the scripts that go with them.
    Extract the scripts folder to a working directory; eg. `/tmp/scripts`, and the
    rpms and downloads folders to a working directory at the same level as the scripts,
    e.q. `/tmp/rpms` and `/tmp/downloads`.

 #. From the working directory, edit the `config` file.

    i)   The `CKAN_DATABASE_PASSWORD` setting needs setting to a randomly
         chosen password that will be used for CKAN user setup for postgresql.

    ii)  The `CKAN_BACKEND_SERVER` needs to be set to the IP address that the
         backend services will be installed on.  This is used to ensure that
         the frontend services are configured correctly.  If you are installing
         everything on the same machine, then leave it as `0.0.0.0`.

    iii) `CKAN_DOMAIN` should be the domain name serving CKAN (on production, ec.europa.eu)

    iv)  All other options should be left as they are.

Backend Services Installation
=============================

 1. First, ensure you have followed the Preliminary steps above.

 #. From within `./scripts`, run the following: ::

      bash ./install_backend_services.sh 2>&1 | tee ./backend_install.log

 #. This will prompt you for a password for the `ecodp` user. Other that that
    it should run without further prompts.

This will install solr, postgres and elasticsearch.

It **will not** touch itables configuration, so you'll need to ensure that
the following ports are available to the frontend machine on your network:

 solr (tomcat) : 8983
 postgresql    : 5432
 elasticsearch : 9200

Frontend Services Installation
==============================

 1. First, **ensure you have followed the preliminary steps above.**

 #. From within `/tmp/scripts`, run the following **as root**: ::

      bash ./install_frontend_services.sh 2>&1 | tee frontend_install.log

 #. This will prompt you for a password for the `ecodp` user.

This will install and configure nginx, apache and CKAN.


Checking that CKAN is installed
===============================

Your CKAN instance should now be available at
http://localhost/open-data/data/

To verify, go to this address in your browser or from the command line, run::

    curl --user <http auth user name>:<http auth password> http://localhost/open-data/data/

The CKAN homepage should be displayed.
