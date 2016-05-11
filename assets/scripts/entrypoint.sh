#!/bin/bash
# inspired by https://github.com/sameersbn/docker-gitlab
set -e

source ${SCRIPT_DIR}/functions

[[ $DEBUG == true ]] && set -x

appInit () {
  # configure database and check connection
  finalize_database_parameters
  check_database_connection

  # create database
  init_database

  # check and prepare SSL keys
  check_and_prepare_SSL

  # configure postfix, dovecot and rsyslog
  configure_postfix
  configure_dovecot
  configure_rsyslog

  # set permission of mail dir and create if not exist
  mkdir -p ${MAIL_DIR}
  chown -R vmail:vmail ${MAIL_DIR}
  chmod u+w ${MAIL_DIR}

  # compile sieve scripts
  echo "Compile sieve scripts"
  sievec /etc/dovecot/sieve-after/spam-to-folder.sieve
}

appStart () {
  # start supervisord
  echo "Starting supervisord..."
  exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
}

appPwGen () {
  doveadm pw -s SHA512-CRYPT
}

appHelp () {
  echo "Available options:"
  echo " app:start          - Starts postfix and dovecot (default)"
  echo " app:check          - Checks the MySQL connection"
  echo " app:pwGen          - Encrypt a password (use with -it)"
  echo " [command]          - Execute the specified linux command eg. bash."
}

case ${1} in
  app:start|app:check|app:pwGen)

    case ${1} in
      app:start)
        appInit
        appStart
      ;;
      app:check)
        appInit
      ;;
      app:pwGen)
        appPwGen
      ;;
    esac
    
    ;;
  app:help)
    appHelp
  ;;
  *)
    exec "$@"
  ;;
esac
