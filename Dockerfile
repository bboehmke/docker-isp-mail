FROM debian:jessie
MAINTAINER Benjamin Böhmke

ENV DATA_DIR=/data \
    MAIL_DIR=/data/maildir

# get and install software
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y supervisor logrotate \
        postfix postfix-mysql swaks dovecot-mysql dovecot-pop3d dovecot-imapd \
        dovecot-managesieved mysql-client rsyslog spamassassin spamass-milter && \
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

# copy new configurations
COPY config/dovecot/ /etc/dovecot/
COPY config/postfix/ /etc/postfix/
COPY config/supervisor/ /etc/supervisor/conf.d/
COPY config/spamassassin/spamassassin /etc/default/spamassassin

# copy crons
COPY config/cron/spamassassin /etc/cron.daily/spamassassin
RUN chmod +x /etc/cron.daily/spamassassin

# prepare entry point
COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh

# set volume
VOLUME "${DATA_DIR}"

# expose ports
#      SMTP    POP3     IMAP
EXPOSE 25 465  110 995  143 993

# set entrypoint
ENTRYPOINT ["/sbin/entrypoint.sh"]
CMD ["app:start"]
