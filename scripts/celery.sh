#!/bin/sh

## Usage:
##
## Source this file, and run install_celery()
##
## This requires the following environment variables to be set:
##
## $CKAN_APPLICATION    : The location of the CKAN application,
##                        eg - /applications/ckan/users/system
## $PYENV               : The location of the python environment.
## $SUPERVISOR_PRODUCT  : The location of the supervisord application.
## $CKAN_INSTANCE       : The ckan instance name
## $CKAN_ETC            : The ckan configuration directory
## $PACKAGE_INSTALL     : Whether to install the python dependencies
##                        from an RPM or not.  If true, then it's assumed
##                        all the python dependencies are met already.
  
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

if [ "X" == "X$SUPERVISOR_PRODUCT" ]
then
  echo 'ERROR: SUPERVISOR_PRODUCT environment variable is not set'
  exit 1
fi

if [ "X" == "X$CKAN_INSTANCE" ]
then
  echo 'ERROR: CKAN_INSTANCE environment variable is not set'
  exit 1
fi

if [ "X" == "X$CKAN_ETC" ]
then
  echo 'ERROR: CKAN_ETC environment variable is not set'
  exit 1
fi

if [ "X" == "X$CKAN_USER" ]
then
  echo 'ERROR: CKAN_USER environment variable is not set'
  exit 1
fi

if [ ! -d "$PYENV" ]
then
  echo 'ERROR: python virtual environment does not exist.'
  exit 1
fi

if [ ! -d "$SUPERVISOR_PRODUCT" ]
then
  echo 'ERROR: The supervisord application is not installed.'
  exit 1
fi

if [ ! "yes" == "$PACKAGE_INSTALL" ] && [ ! "no" == "$PACKAGE_INSTALL" ]
then
  echo 'ERROR: PACKAGE_INSTALL environment variable is not set to either "yes" or "no"'
  exit 1
fi

PIP=$PYENV/bin/pip

install_celery () {


  echo '------------------------------------------'
  echo 'Installing celery'
  echo '------------------------------------------'

  # Only install supervisor if not already installed
  if [ "no" == "$PACKAGE_INSTALL" ]
  then
    $PIP install celery

    # kombu 2.1.8 has an import error
    ## $PIP install kombu==2.1.3
  fi


  echo 'Installing celery under supervisord'
  cat <<EOF > $SUPERVISOR_PRODUCT/etc/conf.d/celery-$CKAN_INSTANCE.conf
; =======================
; ckan celeryd supervisor
; =======================

; symlink or copy this file to /etc/supervisr/conf.d 
; change the path/to/virtualenv below to the virtualenv ckan is in.


[program:celery-$CKAN_INSTANCE]
; Full Path to executable, should be path to virtural environment,
; Full path to config file too.

command=$PYENV/bin/paster --plugin=ckan celeryd --config=$CKAN_ETC/$CKAN_INSTANCE/$CKAN_INSTANCE.ini

; user that owns virtual environment.
user=$CKAN_USER

numprocs=1
stdout_logfile=$CKAN_APPLICATION/ckan/var/log/celeryd.log
stderr_logfile=$CKAN_APPLICATION/ckan/var/log/celeryd.log
autostart=true
autorestart=true
startsecs=10

; Need to wait for currently executing tasks to finish at shutdown.
; Increase this if you have very long running tasks.
stopwaitsecs = 600

; if rabbitmq is supervised, set its priority higher
; so it starts first
priority=998
EOF

echo "Starting celery..."

$PYENV/bin/supervisorctl -c $SUPERVISOR_PRODUCT/etc/supervisord.conf update
$PYENV/bin/supervisorctl -c $SUPERVISOR_PRODUCT/etc/supervisord.conf status
}
