#!/bin/sh

PERCENT=${1}
USER=${2}

case ${PERCENT} in
   inlimit) 
       _SUB_="Information"
       _TXT_="back in its limits"
       ;;
   100) 
       _SUB_="Critical"
       _TXT_="100% full (grace limit is {{QUOTA_GRACE}})"
       ;;
   *)
       _SUB_="Warning"
       _TXT_="${PERCENT}% full"
       ;;
esac

cat << EOF | /usr/lib/dovecot/dovecot-lda -d ${USER} -o "plugin/quota=maildir:User quota:noenforcing"
From: {{MAIL_POSTMASTER_ADDRESS}}
Subject: [MAILBOX] Quota ${_SUB_}

Your mailbox is now ${_TXT_}.
EOF

