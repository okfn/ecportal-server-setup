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

    ii)  The `CKAN_BACKEND_SERVER` needs to be set to the name of server that the
         backend services will be installed on.  This is used to ensure that
         the frontend services are configured correctly.  If you are installing
         everything on the same machine, then leave it as `0.0.0.0`.

    iii) `CKAN_DOMAIN` should be the domain name serving CKAN (on production, ec.europa.eu)

    iv)  `PG_HBA_CONF` can be set to include any custom configuration controlling the
         access to the postgres database.  This can include IP ranges.

    v)   All other options should be left as they are.

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

Afterwards this installation some configurations have to be updated.

Reverse http proxy configuration
--------------------------------

update `${APPROOT}/ngingx/conf.d/default.conf` (if this does not exist check `/etc/nginx/conf.d/default.conf`)

All (four) instances of $host need to be replaced with the hostname of the frontend.
For instance on line 15,  the line 

      proxy_set_header Host $host:80;

must be updated to 

      proxy_set_header Host webgate.acceptance.ec.testa.eu:80;

Also /etc/httpd/conf.d/ecodp.conf needs to be edited.

      ServerName webgate.acceptance.ec.testa.eu
      ServerAlias webgate.acceptance.ec.testa.eu localhost

Afterwards, apache and nginx must be restarted

      service httpd restart
      service nginx restart


Reverse https proxy configuration
---------------------------------
If https is required the following updates must be done.

update `${APPROOT}/ngingx/conf.d/default.conf` (if this does not exist check `/etc/nginx/conf.d/default.conf`)

All (four) instances of $host need to be replaced with the hostname:443, and after each line https forcing statement must be added.
For instance on line 15,  the line 

       proxy_set_header Host $host:80;

must be updated to

       proxy_set_header Host webgate.acceptance.ec.testa.eu:443;
       proxy_set_header X-Forwarded-Proto https;

Update /etc/httpd/conf.d/ecodp.conf. Add a line to the file on root level:

       SetEnvIf X-FORWARDED-PROTO https HTTPS=on

Aftwards, apache and nginx must be restarted

       service nginx restart
       service httpd restart



Checking that CKAN is installed
===============================

Your CKAN instance should now be available at
http://localhost/open-data/data/

To verify, go to this address in your browser or from the command line, run::

    curl --user <http auth user name>:<http auth password> http://localhost/open-data/data/

The CKAN homepage should be displayed.
