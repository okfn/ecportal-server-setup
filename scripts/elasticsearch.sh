#!/bin/sh

## Usage:
##
## Source this file, and run install_elasticsearch()
##
## This requires the following environment variables to be set:
##
## $CKAN_APPLICATION : The location of the CKAN application,
##                     eg - /applications/ckan/users/system

if [ "X" == "X$CKAN_APPLICATION" ]
then
  echo 'ERROR: CKAN_APPLICATION environment variable is not set'
  exit 1
fi

ES_PRODUCT=$CKAN_APPLICATION/elasticsearch

install_elasticsearch () {

  echo '------------------------------------------'
  echo 'Installing elastic search                 '
  echo '------------------------------------------'

  mkdir -p "$ES_PRODUCT"
  
  echo 'Creating elasticsearch user'.
  useradd --system --shell /sbin/nologin elasticsearch
  
  echo 'Increasing number of file descriptors for elasticsearch user'
  cat <<EOF >> /etc/security/limits.conf
elasticsearch   hard    nofile          32000
elasticsearch   soft    nofile          32000
EOF
  
  PREV_DIR=$PWD
  cd "$ES_PRODUCT"
  wget https://github.com/downloads/elasticsearch/elasticsearch/elasticsearch-0.19.4.tar.gz
  tar xzf elasticsearch-0.19.4.tar.gz
  ln -s elasticsearch-0.19.4 elasticsearch
  mkdir -p ${ES_PRODUCT}/run
  chown -R elasticsearch\: ${ES_PRODUCT}/elasticsearch-0.19.4
  chown -R elasticsearch\: ${ES_PRODUCT}/elasticsearch
  chown -R elasticsearch\: ${ES_PRODUCT}/run

  echo 'Installing init.d script for elasticsearch'
  cat <<EOF > /etc/init.d/elasticsearch
#!/bin/sh
#
# Startup script for elasticsearch
#
# chkconfig: 345 80 20
# description: Elasticsearch, a search index server.

# Source init functions
source /etc/rc.d/init.d/functions

ELASTIC_HOME=${ES_PRODUCT}/elasticsearch
PROGNAME="elasticsearch"
PIDFILE=${ES_PRODUCT}/run/elasticsearch.pid
PROG_USER="elasticsearch"
PROG_BIN="\$ELASTIC_HOME/bin/elasticsearch -p \$PIDFILE"

start()
{
        echo -n $"Starting \$PROGNAME: "
        daemon --user \$PROG_USER --pidfile "\$PIDFILE" \$PROG_BIN
        sleep 1
        [ -f \$PIDFILE ] && success $"\$PROGNAME startup" || failure $"\$PROGNAME startup"
        echo
}

stop()
{
        echo -n $"Shutting down \$PROGNAME: "
        [ -f \$PIDFILE ] && killproc -p "\$PIDFILE" \$PROGNAME || success $"\$PROGNAME shutdown"
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
        status -p \$PIDFILE \$PROGNAME
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

  ln -s /etc/init.d/elasticsearch $CKAN_APPLICATION/init.d/elasticsearch

  chmod +x /etc/init.d/elasticsearch
  chkconfig --add elasticsearch
  chkconfig elasticsearch on --level 345
  chkconfig --list elasticsearch

  echo 'Setting log directory for elasticsearch'
  mkdir -p /var/log/elasticsearch
  chown elasticsearch\: /var/log/elasticsearch

  sed -e 's,^# path.logs: /path/to/logs$,path.logs: /var/log/elasticsearch,' \
      -i $ES_PRODUCT/elasticsearch/config/elasticsearch.yml

  echo "Setting file permissions on $ES_PRODUCT"
  chown -R elasticsearch "$ES_PRODUCT"
  chgrp -R elasticsearch "$ES_PRODUCT"

  $CKAN_APPLICATION/init.d/elasticsearch start

  cd "$PREV_DIR"

}
