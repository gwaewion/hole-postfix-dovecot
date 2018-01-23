FROM alpine:latest
LABEL maintainer="gwaewion@gmail.com"
EXPOSE 25 143 587 993 10026
VOLUME /mail

ENV DB_SERVER_ADDRESS CHANGE_ME
ENV DB_NAME CHANGE_ME
ENV DB_USER CHANGE_ME
ENV DB_USER_PASSWORD CHANGE_ME
ENV FQDN CHANGE_ME
ENV MAIL_DOMAIN CHANGE_ME
ENV CLAMAV_ADDRESS CHANGE_ME

RUN apk update
RUN apk add dovecot dovecot-mysql postfix postfix-mysql postfix-pcre mariadb-client rsyslog shadow
RUN mkdir /etc/postfix/sql
COPY dovecot.conf dovecot-sql.conf /etc/dovecot/
COPY sql_virtual_alias_domain_catchall_maps.cf sql_virtual_alias_domain_mailbox_maps.cf sql_virtual_alias_domain_maps.cf sql_virtual_alias_maps.cf sql_virtual_domains_maps.cf sql_virtual_mailbox_maps.cf /etc/postfix/sql/
COPY main.cf master.cf /etc/postfix/
COPY run.sh /root

CMD ["sh", "/root/run.sh"]
