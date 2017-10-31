FROM debian:jessie
MAINTAINER Benjamin Boehmke <benjamin@boehmke.net>; Dennis Twardowsky <twardowsky@gmail.com>

ENV DATA_DIR=/data \
    MAIL_DIR=/data/maildir \
    SCRIPT_DIR=/opt/scripts

# get and install software
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y supervisor logrotate \
        postfix postfix-mysql postfix-pgsql swaks dovecot-mysql dovecot-pgsql \
        dovecot-pop3d dovecot-imapd dovecot-managesieved mysql-client \
        postgresql-client rsyslog spamassassin spamass-milter sudo gettext-base && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# FIX Debian bug #739738
RUN sed 's/return if \!/return undef if \!/g' -i /usr/share/perl5/Mail/SpamAssassin/Util.pm

# move original configurations and cron files
RUN mv /etc/dovecot /etc/dovecot.org && \
    mv /etc/postfix /etc/postfix.org && \
    mv /etc/default/spamassassin /etc/default/spamassassin.org && \
    mv /etc/cron.daily/spamassassin /etc/cron.daily/spamassassin.org && \
    chmod -x /etc/cron.daily/*.org

# create vmail user and add spamass-milter to debian-spamd group
RUN groupadd -g 5000 vmail && \
    useradd -g vmail -u 5000 vmail -d ${MAIL_DIR} && \
    adduser spamass-milter debian-spamd

# TODO move up
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y 

# copy new configurations
COPY assets/config/dovecot/ /etc/dovecot/
COPY assets/config/postfix/ /etc/postfix/
COPY assets/config/supervisor/ /etc/supervisor/conf.d/
COPY assets/config/spamassassin/spamassassin /etc/default/spamassassin
COPY assets/sql/ /etc/isp-mail/sql/

# copy crons
COPY assets/config/cron/spamassassin /etc/cron.daily/spamassassin
RUN chmod +x /etc/cron.daily/spamassassin

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
