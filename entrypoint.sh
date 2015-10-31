#!/bin/bash
# inspired by https://github.com/sameersbn/docker-gitlab
set -e

# default settings
SERVER_HOSTNAME=${SERVER_HOSTNAME:-$HOSTNAME}
MAILBOX_SIZE=${MAILBOX_SIZE:-0}
POSTMASTER_ADDRESS={$POSTMASTER_ADDRESS:-"root"}

# SSL settings
SSL_KEY=${SSL_KEY:-mail.key}
SSL_CERT=${SSL_CERT:-mail.crt}
DH_PARAM_LENGTH=${DH_PARAM_LENGTH:-1024}

# check if cert and key exists
if [[ ! -f "${DATA_DIR}/ssl/${SSL_KEY}" || 
      ! -f "${DATA_DIR}/ssl/${SSL_CERT}" ]]; then
  echo "ERROR: "
  echo "  Please configure the SSL settings."
  echo "  Cannot continue without a SSL certificate and key. Aborting..."
  exit 1
fi

# check if database connection defined
if [[ -z ${MYSQL_USER} || 
      -z ${MYSQL_PASSWORD} || 
      -z ${MYSQL_HOST} || 
      -z ${MYSQL_DATABASE} ]]; then
  echo "ERROR: "
  echo "  Please configure the database connection."
  echo "  Cannot continue without a database. Aborting..."
  exit 1
fi
MYSQL_PORT=${MYSQL_PORT:-3306}


# prepare MySQL queries
MYSQL_QUERY_VIRTUAL_DOMAINS="SELECT 1 FROM virtual_domains WHERE name='%s'"
MYSQL_QUERY_VIRTUAL_MAIL="SELECT 1 FROM virtual_users JOIN virtual_domains ON virtual_users.domain_id = virtual_domains.id WHERE CONCAT(virtual_users.name,\"@\",virtual_domains.name)='%s'"
MYSQL_QUERY_VIRTUAL_ALIAS="SELECT destination FROM virtual_aliases JOIN virtual_domains ON virtual_aliases.domain_id = virtual_domains.id WHERE concat(virtual_aliases.source,\"@\",virtual_domains.name)='%s'"
MYSQL_QUERY_VIRTUAL_MAIL_MAIL="SELECT CONCAT(virtual_users.name,\"@\",virtual_domains.name) AS email FROM virtual_users JOIN virtual_domains ON virtual_users.domain_id = virtual_domains.id WHERE virtual_users.name = '%u' AND virtual_domains.name ='%d'"
MYSQL_QUERY_PASSWORD="SELECT virtual_users.name AS username, virtual_domains.name AS domain, password FROM virtual_users JOIN virtual_domains ON virtual_users.domain_id = virtual_domains.id WHERE virtual_users.name = '%n' AND virtual_domains.name = '%d'"
MYSQL_QUERY_USER="SELECT 5000 AS uid, 5000 AS gid, '${MAIL_DIR}/%d/%n' AS home FROM virtual_users JOIN virtual_domains ON virtual_users.domain_id = virtual_domains.id WHERE virtual_users.name = '%n' AND virtual_domains.name ='%d'"


# Postfix - main.cf
sed 's/{{HOSTNAME}}/'"${SERVER_HOSTNAME}"'/g' -i /etc/postfix/main.cf
sed 's/{{MAILBOX_SIZE}}/'"${MAILBOX_SIZE}"'/g' -i /etc/postfix/main.cf
sed 's,{{SSL_KEY}},'"${DATA_DIR}/ssl/${SSL_KEY}"',g' -i /etc/postfix/main.cf
sed 's,{{SSL_CERT}},'"${DATA_DIR}/ssl/${SSL_CERT}"',g' -i /etc/postfix/main.cf

# Postfix - MySQL
# > prepare generic settings
sed 's/{{MYSQL_HOST}}/'"${MYSQL_HOST}"'/g' -i /etc/postfix/mysql_tpl.cf
sed 's/{{MYSQL_USER}}/'"${MYSQL_USER}"'/g' -i /etc/postfix/mysql_tpl.cf
sed 's/{{MYSQL_PASSWORD}}/'"${MYSQL_PASSWORD}"'/g' -i /etc/postfix/mysql_tpl.cf
sed 's/{{MYSQL_DATABASE}}/'"${MYSQL_DATABASE}"'/g' -i /etc/postfix/mysql_tpl.cf
mkdir -p /etc/postfix/mysql
# > virtual domains
cp /etc/postfix/mysql_tpl.cf /etc/postfix/mysql/virtual_mailbox_domains.cf
sed 's/{{MYSQL_QUERY}}/'"${MYSQL_QUERY_VIRTUAL_DOMAINS}"'/g' -i /etc/postfix/mysql/virtual_mailbox_domains.cf
# > virtual mails
cp /etc/postfix/mysql_tpl.cf /etc/postfix/mysql/virtual_mailbox_maps.cf
sed 's/{{MYSQL_QUERY}}/'"${MYSQL_QUERY_VIRTUAL_MAIL}"'/g' -i /etc/postfix/mysql/virtual_mailbox_maps.cf
# > virtual alias
cp /etc/postfix/mysql_tpl.cf /etc/postfix/mysql/virtual_alias_maps.cf
sed 's/{{MYSQL_QUERY}}/'"${MYSQL_QUERY_VIRTUAL_ALIAS}"'/g' -i /etc/postfix/mysql/virtual_alias_maps.cf
# > virtual mail to mail (alias)
cp /etc/postfix/mysql_tpl.cf /etc/postfix/mysql/email2email.cf
sed 's/{{MYSQL_QUERY}}/'"${MYSQL_QUERY_VIRTUAL_MAIL_MAIL}"'/g' -i /etc/postfix/mysql/email2email.cf


# Dovecot - mail dir
sed 's,{{MAIL_DIR}},'"${MAIL_DIR}"',g' -i /etc/dovecot/conf.d/10-mail.conf

# Dovecot - LDA
sed 's,{{POSTMASTER_ADDRESS}},'"${POSTMASTER_ADDRESS}"',g' -i /etc/dovecot/conf.d/15-lda.conf

# Dovecot - SSL
sed 's,{{SSL_KEY}},'"${DATA_DIR}/ssl/${SSL_KEY}"',g' -i /etc/dovecot/conf.d/10-ssl.conf
sed 's,{{SSL_CERT}},'"${DATA_DIR}/ssl/${SSL_CERT}"',g' -i /etc/dovecot/conf.d/10-ssl.conf
sed 's/{{DH_PARAM_LENGTH}}/'"${DH_PARAM_LENGTH}"'/g' -i /etc/dovecot/conf.d/10-ssl.conf

# Dovecot - MySQL
sed 's/{{MYSQL_HOST}}/'"${MYSQL_HOST}"'/g' -i /etc/dovecot/dovecot-sql.conf.ext
sed 's/{{MYSQL_USER}}/'"${MYSQL_USER}"'/g' -i /etc/dovecot/dovecot-sql.conf.ext
sed 's/{{MYSQL_PASSWORD}}/'"${MYSQL_PASSWORD}"'/g' -i /etc/dovecot/dovecot-sql.conf.ext
sed 's/{{MYSQL_DATABASE}}/'"${MYSQL_DATABASE}"'/g' -i /etc/dovecot/dovecot-sql.conf.ext
sed 's/{{MYSQL_QUERY_PASSWORD}}/'"${MYSQL_QUERY_PASSWORD}"'/g' -i /etc/dovecot/dovecot-sql.conf.ext
sed 's;{{MYSQL_QUERY_USER}};'"${MYSQL_QUERY_USER}"';g' -i /etc/dovecot/dovecot-sql.conf.ext

# move log files to data dir
mkdir -p ${DATA_DIR}/log/
sed 's;/var/log/mail;'"${DATA_DIR}/log/mail"';g' -i /etc/rsyslog.conf
sed 's;/var/log/mail;'"${DATA_DIR}/log/mail"';g' -i /etc/logrotate.d/rsyslog

# set cert and key permissins
chmod 600 "${DATA_DIR}/ssl/${SSL_KEY}"
chmod 600 "${DATA_DIR}/ssl/${SSL_CERT}"

# set permissions of config files
# > postfix
chgrp postfix /etc/postfix/mysql/*.cf
chmod u=rw,g=r,o= /etc/postfix/mysql/*.cf
# > dovecot
chgrp vmail /etc/dovecot/dovecot.conf
chmod g+r /etc/dovecot/dovecot.conf
chown root:root /etc/dovecot/dovecot-sql.conf.ext
chmod go= /etc/dovecot/dovecot-sql.conf.ext


# set permission of mail dir and create if not exist
mkdir -p ${MAIL_DIR}
chown -R vmail:vmail ${MAIL_DIR}
chmod u+w ${MAIL_DIR}

# add missing files to postfix chroot
cp -f /etc/services /var/spool/postfix/etc/services
cp -f /etc/resolv.conf /var/spool/postfix/etc/resolv.conf
cp -f /etc/aliases /var/spool/postfix/etc/aliases

appInit () {
  # due to the nature of docker and its use cases, we allow some time
  # for the database server to come online.
  prog="mysqladmin -h ${MYSQL_HOST} -P ${MYSQL_PORT} -u ${MYSQL_USER} -p${MYSQL_PASSWORD} status"
  timeout=60
  echo -n "Waiting for database server to accept connections"
  while ! ${prog} >/dev/null 2>&1
  do
    timeout=$(expr $timeout - 1)
    if [[ $timeout -eq 0 ]]; then
      echo
      echo "Could not connect to database server. Aborting..."
      exit 1
    fi
    echo -n "."
    sleep 1
  done
  echo

  echo "Create MySQL table if not exist"
  mysql -h ${MYSQL_HOST} -P ${MYSQL_PORT} -u ${MYSQL_USER} -p${MYSQL_PASSWORD} -D ${MYSQL_DATABASE} < /etc/postfix/mail.sql

  # generate dh param for postfix
  echo "Start Generating DH parameters this may take some time ..."
  openssl gendh -out /etc/postfix/dh_512.pem -2 512
  openssl gendh -out /etc/postfix/dh_1024.pem -2 ${DH_PARAM_LENGTH}

  # compile sieve scripts
  echo "Compile sieve scripts"
  sievec /etc/dovecot/sieve-after/spam-to-folder.sieve
}

appStart () {
  echo 
  echo "Prepare start of of Server"
  appInit
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
  app:start)
    appStart
    ;;
  app:check)
    appInit
    ;;
  app:pwGen)
    appPwGen
    ;;
  *)
    if [[ -x $1 ]]; then
      $1
    else
      prog=$(which $1)
      if [[ -n ${prog} ]] ; then
        shift 1
        $prog $@
      else
        appHelp
      fi
    fi
  ;;
esac

exit 0