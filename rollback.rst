Backend Services
================

Solr
----

0.  Stop the service

    - ``/etc/init.d/tomcat6 stop``

1.  Uninstall tomcat6 package and dependenceis, and clean up residual files.

    - ``yum erase tomcat6 tomcat6-lib tomcat6-el-2.1-api tomcat6-jsp-2.1-api tomcat6-servlet-2.5-api``
    - ``rm -rf /var/lib/tomcat6 /etc/tomcat6 /var/log/tomcat6 /usr/share/java/tomcat6 /usr/share/tomcat6``

2.  Remove from /applications/....

    - ``rm -rf /applications/ecodp/users/ecodp/tomcat /applications/ecodp/users/ecodp/solr /applications/ecodp/users/ecodp/init.d/tomcat6``

3.  Remove tomcat user

    - ``userdel -rZ tomcat``

Postgresql
----------

0.  Stop the service

    - ``/etc/init.d/postgresql stop``

1.  Uninstall postgresql and dependencies.

    - ``yum erase postgresql postgresql-server postgresql-libs``
    - ``rm -rf /applications/ecodp/users/ecodp/postgres /applications/ecodp/users/ecodp/init.d/postgresql``

2.  Remove postgres user

    - ``userdel -rZ postgres``

ElsaticSearch
-------------

0.  Stop the service

    - ``/etc/init.d/elasticsearch stop``

1.  Remove installation directory

    - ``rm -rf /applications/ecodp/users/ecodp/elasticsearch``
    - ``rm -rf /applications/ecodp/users/ecodp/init.d/elasticsearch``
    - ``rm -rf /etc/init.d/elasticsearch``
    - ``rm -rf rm -rf /var/log/elasticsearch``

2.  Uninstall elasticsearch user

    - ``userdel -rZ elasticsearch``

3.  Remove filedescriptor limits for elasticsearch user

    - ``sed -e '/^elasticsearch/d' -i /etc/security/limits.conf``

Frontend Services
=================

Nginx
-----

0.  Stop the service

    - ``/etc/init.d/nginx stop``

1.  Uninstall the pacakge

    - ``rpm --erase nginx``

2.  Uninstall residual files

    - ``rm -rf /etc/nginx /applications/ecodp/users/ecodp/nginx /applications/ecodp/users/ecodp/init.d/nginx``
    - ``rm -rf /var/log/nginx /var/cache/nginx``

3.  Remove the nginx user

    - ``userdel -rZ nginx``

CKAN
----

0.  Stop the service

    - ``/etc/init.d/httpd stop``

1.  Uninstall the pyenv package

    - ``rpm --erase ecportal-python-virtual-environment``

2.  Uninstall non-python dependencies

    NOTE: This will remove apache, which is a shared dependency for other
    projects in ECODP, eg. the drupal site.  If you don't wish to uninstall
    apache, then remove the ``httpd``, ``httpd-tools`` and ``apr-util-ldap``
    from the following command.

    - ``yum erase postgresql postgresql-libs mod_wsgi httpd httpd-tools apr-util-ldap``

3.  Remove apache files

    - ``rm -rf /etc/httpd/conf.d/0-wsgi.conf /etc/httpd/conf.d/0-rewrite.conf``
    - ``rm -rf /etc/httpd/conf.d/ecodp.conf`` [Optional, as it is a shared
      dependency with drupal etc.]
    - ``rm -rf /applications/ecodp/users/ecodp/init.d/httpd``
    - ``rm -rf /var/log/httpd``

4.  Delete users

    - ``userdel -rZ apache``
    - ``userdel -rZ ckanecodp``

5.  Delete CKAN directory

    - ``rm -rf /applications/ecodp/users/ecodp/ckan``

6.  Delete supervisord

    - ``rm -rf /applications/ecodp/users/ecodp/supervisor``
    - ``rm -rf /etc/init.d/supervisord``

7.  Remove cronjobs

    Remove ``--plugin=ckan`` cronjobs from the following cron table:

      ``crontab -u ecodp -e``

    And the ``find /applications/ecodp/users/ecodp/ckan/lib/ecodp/data/`` from
    the following cron table:

      ``crontab -u apache -e``

Common Step
===========

These are setup on both the frontend and backend.  The common rollback steps
should be followed **after** following the fronted or backend steps.

1.  Remove ecodp user and group

    - ``userdel -rZ ecodp``
    - ``groupdel ecodp``

2.  Remove ckan from /applications/...

    - ``rm -rf /applications/ecodp/users/ecodp/ckan``
    - ``rm -rf /applications/ecodp/users/ecodp/init.d``

3.  Remove some of the tools used.

    - ``yum erase python-setuptools policycoreutils-python``
