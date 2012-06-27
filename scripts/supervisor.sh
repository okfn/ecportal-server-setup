#!/bin/sh

## Usage:
##
## Source this file, and run install_supervisor()
##
## This requires the following environment variables to be set:
##
## $CKAN_APPLICATION : The location of the CKAN application,
##                     eg - /applications/ckan/users/system
## $PYENV            : The location of the python environment.

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

SUPERVISOR_PRODUCT=$CKAN_APPLICATION/supervisor

install_supervisor () {

  echo '------------------------------------------'
  echo 'Installing supervisord'
  echo '------------------------------------------'

  PIP=$PYENV/bin/pip

  mkdir -p "$SUPERVISOR_PRODUCT"

  $PIP install supervisor
  mkdir -p $SUPERVISOR_PRODUCT/etc/conf.d
  mkdir -p $SUPERVISOR_PRODUCT/var/run
  mkdir -p $SUPERVISOR_PRODUCT/var/log/supervisor
  $PYENV/bin/echo_supervisord_conf | \
  sed \
    -e "s,^file=.*,file=$SUPERVISOR_PRODUCT/var/run/supervisor.sock," \
    -e "s,^pidfile=.*,pidfile=$SUPERVISOR_PRODUCT/var/run/supervisor.pid," \
    -e "s,^logfile=.*,logfile=$SUPERVISOR_PRODUCT/var/log/supervisord.log," \
    -e "s,^;\?childlogdir=.*,childlogdir=$SUPERVISOR_PRODUCT/var/log/supervisor," \
    -e "s,^serverurl=.*,serverurl=unix://$SUPERVISOR_PRODUCT/var/run/supervisor.sock," \
    -e "s,^;\[include\],[include]," \
    -e "s,^;user=.*,user=$CKAN_USER," \
    -e "s,^;\?files =.*,files=$SUPERVISOR_PRODUCT/etc/conf.d/*.conf," > $SUPERVISOR_PRODUCT/etc/supervisord.conf

  cat <<EOF > /etc/init.d/supervisord
#!/bin/sh
#
# Startup script for supervidord
#
# chkconfig: 345 80 20
# description: Supervisord, monitors processes

# Source init functions
source /etc/rc.d/init.d/functions

PROG="supervisord"
PROG_BIN="$PYENV/bin/supervisord -c $SUPERVISOR_PRODUCT/etc/supervisord.conf"
PIDFILE="$SUPERVISOR_PRODUCT/var/run/supervisor.pid"

start()
{
        echo -n $"Starting \$PROG: "
        daemon --pidfile "\$PIDFILE" \$PROG_BIN
        sleep 1
        [ -f \$PIDFILE ] && success $"\$PROG startup" || failure $"\$PROG startup"
        echo
}

stop()
{
        echo -n $"Shutting down \$PROG: "
        [ -f \$PIDFILE ] && killproc -p "\$PIDFILE" \$PROG || success $"\$PROG shutdown"
        echo
}

case "\$1" in

  start)
    start
  ;;

  stop)
    stop
  ;;

  status)
        status -p \$PIDFILE \$PROG
  ;;

  restart)
    stop
    start
  ;;

  *)
    echo "Usage: \$0 {start|stop|restart|status}"
  ;;
esac

EOF

  ln -s /etc/init.d/supervisord $CKAN_APPLICATION/init.d/supervisord
  chmod +x /etc/init.d/supervisord
  chkconfig --add supervisord
  chkconfig supervisord on --level 345
  chkconfig --list supervisord

echo "Setting permissions on $SUPERVISOR_PRODUCT"
chown -R $CKAN_USER "$SUPERVISOR_PRODUCT"
chgrp -R $CKAN_USER "$SUPERVISOR_PRODUCT"

echo 'Starting supervisord...'
chmod +x $CKAN_APPLICATION/init.d/supervisord
$CKAN_APPLICATION/init.d/supervisord start

}
