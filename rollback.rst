Backend Services
================

Solr
----

1.  Uninstall tomcat6 package and dependenceis, and clean up residual files.

    - ``yum erase tomcat6 tomcat6-lib tomcat6-el-2.1-api tomcat6-jsp-2.1-api tomcat6-servlet-2.5-api``
    - ``rm -rf /var/lib/tomcat6 /etc/tomcat6 /var/log/tomcat6 /usr/share/java/tomcat6 /usr/share/tomcat6``

2.  Remove from /applications/....

    - ``rm -rf /applications/ecodp/users/ecodp/tomcat``
    - ``rm -rf /applications/ecodp/users/ecodp/solr``
    - ``rm -f /applications/ecodp/users/ecodp/init.d/tomcat6``

3.  Remove tomcat user

    - ``userdel -rZ tomcat``

Postgresql
----------

1.  Uninstall postgresql and dependencies.

    - ``yum erase postgresql postgresql-server postgresql-libs``
    - ``rm -rf /applications/ecodp/users/ecodp/postgres /applications/ecodp/users/ecodp/init.d/postgresql``

2.  Remove postgres user

    - ``userdel -rZ postgres``

ElsaticSearch
-------------

1.  Remove installation directory

    - ``rm -rf /applications/ecodp/users/ecodp/elasticsearch``
    - ``rm -rf /applications/ecodp/users/ecodp/init.d/elasticsearch``
    - ``rm -rf /etc/init.d/elasticsearch``
    - ``rm -rf rm -rf /var/log/elasticsearch``

2.  Uninstall elasticsearch user

    - ``userdel -rZ elasticsearch``

3.  Remove filedescriptor limits for elasticsearch user

    - ``sed -e '/^elasticsearch/d' -i /etc/security/limits.conf``

    
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
