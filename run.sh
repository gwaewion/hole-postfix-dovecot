#!/bin/sh

if [ -f /mail/etc/dovecot/dovecot.conf ] && [ -f /mail/etc/postfix/main.cf ]
then
	# starting postfix and dovecot

	rsyslogd
	postfix -c /mail/etc/postfix start
	dovecot -c /mail/etc/dovecot/dovecot.conf -F

else

	# rsyslog initialization 

	sed -i "s/\/var\/log\/maillog/\/mail\/log\/maillog/" /etc/rsyslog.conf

	# postfix initialization

	export VMAIL_UID=$(grep vmail /etc/passwd | tr ":" " " | awk '{print $3};')
	export VMAIL_GID=$(grep vmail /etc/passwd | tr ":" " " | awk '{print $4};')

	cd /mail
	mkdir -p log etc/postfix etc/dovecot domains spool/postfix
	cp -R /etc/postfix/* /mail/etc/postfix/
	
	sed -i "s/myhostname=/myhostname="${FQDN}"/" /mail/etc/postfix/main.cf
	sed -i "s/mydomain=/mydomain="${MAIL_DOMAIN}"/" /mail/etc/postfix/main.cf
	sed -i "s/virtual_gid_maps = static:/virtual_gid_maps = static:"${VMAIL_GID}"/" /mail/etc/postfix/main.cf
	sed -i "s/virtual_uid_maps = static:/virtual_uid_maps = static:"${VMAIL_UID}"/" /mail/etc/postfix/main.cf
	sed -i "s/content_filter = scan\:\[\]\:10025/content_filter = scan\:\["${CLAMAV_ADDRESS}"\]\:10025/" /mail/etc/postfix/main.cf
	
	cd /mail/etc/postfix/sql
	sed -i "s/user = /user = "${DB_USER}"/" sql_*.cf
	sed -i "s/password = /password = "${DB_USER_PASSWORD}"/" sql_*.cf
	sed -i "s/hosts = /hosts = "${DB_SERVER_ADDRESS}"/" sql_*.cf
	sed -i "s/dbname = /dbname = "${DB_NAME}"/" sql_*.cf

	chown -R vmail:postdrop /mail/domains
	usermod -d /mail/domains vmail
	# chown -R postfix:postfix /mail/etc/postfix/sql
	# chmod 640 /mail/etc/postfix/sql 
	
	# dovecot initialization

	cd /mail
	mkdir -p etc/dovecot
	cp -R /etc/dovecot/* /mail/etc/dovecot/	
	
	cd /mail/etc/dovecot
	sed -i "s/first_valid_gid =/first_valid_gid = "${VMAIL_GID}"/" dovecot.conf
	sed -i "s/first_valid_uid =/first_valid_uid = "${VMAIL_UID}"/" dovecot.conf
	sed -i "s/last_valid_gid =/last_valid_gid = "${VMAIL_GID}"/" dovecot.conf
	sed -i "s/last_valid_uid =/last_valid_uid = "${VMAIL_UID}"/" dovecot.conf
	sed -i "s/args = uid= gid= home=\/mail\/domains\/%d\/%n/args = uid="${VMAIL_UID}" gid="${VMAIL_GID}" home=\/mail\/domains\/%d\/%n/" dovecot.conf
	sed -i "s/connect = host= dbname= user= password=/connect = host="${DB_SERVER_ADDRESS}" dbname="${DB_NAME}" user="${DB_USER}" password="${DB_USER_PASSWORD}"/" dovecot-sql.conf
	chown root:root /mail/etc/dovecot/dovecot-sql.conf
	chmod 600 /mail/etc/dovecot/dovecot-sql.conf

	rm -rf /etc/postfix
	rm -rf /etc/dovecot

	rsyslogd
	postfix -c /mail/etc/postfix start
	dovecot -c /mail/etc/dovecot/dovecot.conf -F

fi