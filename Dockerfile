FROM debian:stretch

ENV DATA_DIR=/data \
    MAIL_DIR=/data/maildir \
    SCRIPT_DIR=/opt/scripts

# get and install software
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y supervisor logrotate wget \
        postfix postfix-mysql postfix-pgsql swaks dovecot-mysql dovecot-pgsql \
        dovecot-pop3d dovecot-imapd dovecot-lmtpd dovecot-managesieved mysql-client \
        postgresql-client rsyslog redis-server pwgen sudo gettext-base \
        python3 python3-pip && \
    wget -O- https://rspamd.com/apt-stable/gpg.key | apt-key add - && \
    echo "deb http://rspamd.com/apt-stable/ stretch main" > /etc/apt/sources.list.d/rspamd.list && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y rspamd && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# move original configurations and cron files
RUN mv /etc/dovecot /etc/dovecot.org && \
    mv /etc/postfix /etc/postfix.org && mkdir /etc/postfix && cp -r /etc/postfix.org/postfix-files* /etc/postfix

# create vmail user 
RUN groupadd -g 5000 vmail && \
    useradd -g vmail -u 5000 vmail -d ${MAIL_DIR} && \
    adduser debian-spamd

# TODO move up
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y 

# copy new configurations
COPY assets/config/dovecot/ /etc/dovecot/
COPY assets/config/postfix/ /etc/postfix/
COPY assets/config/rspamd/local.d /etc/rspamd/local.d/
COPY assets/config/rspamd/override.d /etc/rspamd/override.d/
COPY assets/config/supervisor/ /etc/supervisor/conf.d/
COPY assets/sql/ /etc/isp-mail/sql/

# prepare entry point
COPY assets/scripts ${SCRIPT_DIR}
RUN chmod 755 ${SCRIPT_DIR}/entrypoint.sh

# copy management scripts
COPY assets/admin /usr/local/bin
RUN chmod 755 /usr/local/bin/*

# set volume
VOLUME "${DATA_DIR}"

# expose ports
#      SMTP    POP3     IMAP     Sieve
EXPOSE 25 465  110 995  143 993  4190

# set entrypoint
ENTRYPOINT ["/opt/scripts/entrypoint.sh"]
CMD ["app:start"]
