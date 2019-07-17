#!/bin/bash
clear
yum install cowsay -y
clear
echo ""
cowsay "NOW I WILL INSTALL FOR YOU FREEPBX 14 AND ASTERISK 13. GRAB SOME MILK AND WAIT UNTILL YOU WILL PROMT TO GO TO MYSQL STEP"
echo ""
sleep 5
clear
echo ""
cowsay "DISABLE SELINUX"
echo ""
sleep 5
sed -i 's/\(^SELINUX=\).*/\SELINUX=disabled/' /etc/sysconfig/selinux
sed -i 's/\(^SELINUX=\).*/\SELINUX=disabled/' /etc/selinux/config
setenforce 0
clear
echo ""
cowsay "UPDATE YOUR SYSTEM"
echo ""
sleep 5
yum -y update
yum -y groupinstall core base "Development Tools"
clear
echo ""
cowsay "ADD THE ASTERISK USER"
echo ""
sleep 5
adduser asterisk -m -c "Asterisk User"
clear
echo ""
cowsay "INSTALL ADDITIONAL REQUIRED DEPENDENCIES"
echo ""
sleep 5
yum -y install lynx tftp-server unixODBC mysql-connector-odbc mariadb-server mariadb httpd ncurses-devel sendmail sendmail-cf sox newt-devel libxml2-devel libtiff-devel audiofile-devel gtk2-devel subversion kernel-devel git crontabs cronie cronie-anacron wget vim uuid-devel sqlite-devel net-tools gnutls-devel python-devel texinfo libuuid-devel
clear
echo ""
cowsay "INSTALL PHP 5.6 REPOSITORIES"
echo ""
sleep 5
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
clear
echo ""
cowsay "INSTALL PHP5.6W"
echo ""
sleep 5
yum remove php*
yum install -y php56w php56w-pdo php56w-mysql php56w-mbstring php56w-pear php56w-process php56w-xml php56w-opcache php56w-ldap php56w-intl php56w-soap
clear
echo ""
cowsay "INSTALL NODEJS"
echo ""
sleep 5
curl -sL https://rpm.nodesource.com/setup_12.x | bash -
yum install -y nodejs
clear
echo ""
cowsay "ENABLE AND START MARIADB"
echo ""
sleep 5
systemctl enable mariadb.service
systemctl start mariadb
clear
echo ""
cowsay "Now that our MariaDB database is running, we want to run a simple security script that will remove some dangerous defaults and lock down access to our database system a little bit. The prompt will ask you for your current root password. Since you just installed MySQL, you most likely won’t have one, so leave it blank by pressing enter. Then the prompt will ask you if you want to set a root password. Do not set a root password. We secure the database automatically, as part of the install script.  Apart from that you can chose yes for the rest. This will remove some sample users and databases, disable remote root logins, and load these new rules so that MySQL immediately respects the changes we have made."
echo ""
sleep 30
mysql_secure_installation
clear
echo ""
cowsay "ENABLE AND START APACHE"
echo ""
sleep 5
systemctl enable httpd.service
systemctl start httpd.service
clear
echo ""
cowsay "INSTALL LEGACY PEAR REQUIREMENTS"
echo ""
sleep 5
pear install Console_Getopt
clear
echo ""
cowsay "INSTALL AND CONFIGURE ASTERISK"
echo ""
sleep 5
cd /usr/src
wget -O jansson.tar.gz https://github.com/akheron/jansson/archive/v2.12.tar.gz
wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-13-current.tar.gz
clear
echo ""
cowsay "COMPILE AND INSTALL JANSSON"
echo ""
sleep 5
cd /usr/src
tar vxfz jansson.tar.gz
rm -f jansson.tar.gz
cd jansson-*
autoreconf -i
./configure --libdir=/usr/lib64
make
make install
clear
echo ""
cowsay "COMPILE AND INSTALL ASTERISK"
echo ""
sleep 5
cd /usr/src
tar xvfz asterisk-13-current.tar.gz
rm -f asterisk-*-current.tar.gz
cd asterisk-*
contrib/scripts/install_prereq install
./configure --libdir=/usr/lib64 --with-pjproject-bundled --with-jansson-bundled
contrib/scripts/get_mp3_source.sh
clear
echo ""
cowsay "MENU SELECT (If you are using Asterisk 16, enable format_mp3, res_config_mysql, app_macro)"
echo ""
sleep 5
make menuselect
make
make install
make config
ldconfig
chkconfig asterisk off
clear
echo ""
cowsay "SET ASTERISK OWNERSHIP PERMISSIONS"
echo ""
sleep 5
chown asterisk. /var/run/asterisk
chown -R asterisk. /etc/asterisk
chown -R asterisk. /var/{lib,log,spool}/asterisk
chown -R asterisk. /usr/lib64/asterisk
chown -R asterisk. /var/www/
clear
echo ""
cowsay "INSTALL AND CONFIGURE FREEPBX"
echo ""
sleep 5
sed -i 's/\(^upload_max_filesize = \).*/\120M/' /etc/php.ini
sed -i 's/^\(User\|Group\).*/\1 asterisk/' /etc/httpd/conf/httpd.conf
sed -i 's/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf
systemctl restart httpd.service
clear
echo ""
cowsay "DOWNLOAD AND INSTALL FREEPBX"
echo ""
sleep 5
cd /usr/src
wget http://mirror.freepbx.org/modules/packages/freepbx/freepbx-14.0-latest.tgz
tar xfz freepbx-14.0-latest.tgz
rm -f freepbx-14.0-latest.tgz
cd freepbx
cat >> /usr/sbin/safe_asterisk << EOF
#!/bin/sh

ASTETCDIR="__ASTERISK_ETC_DIR__"
ASTSBINDIR="__ASTERISK_SBIN_DIR__"
ASTVARRUNDIR="__ASTERISK_VARRUN_DIR__"
ASTVARLOGDIR="__ASTERISK_LOG_DIR__"

CLIARGS="$*"			# Grab any args passed to safe_asterisk
TTY=9				# TTY (if you want one) for Asterisk to run on
CONSOLE=yes			# Whether or not you want a console
#NOTIFY=root@localhost		# Who to notify about crashes
#EXEC=/path/to/somescript	# Run this command if Asterisk crashes
#LOGFILE="${ASTVARLOGDIR}/safe_asterisk.log"	# Where to place the normal logfile (disabled if blank)
#SYSLOG=local0			# Which syslog facility to use (disabled if blank)
MACHINE=`hostname`		# To specify which machine has crashed when getting the mail
DUMPDROP="${DUMPDROP:-/tmp}"
RUNDIR="${RUNDIR:-/tmp}"
SLEEPSECS=4
ASTPIDFILE="${ASTVARRUNDIR}/asterisk.pid"

# comment this line out to have this script _not_ kill all mpg123 processes when
# asterisk exits
KILLALLMPG123=1

# run asterisk with this priority
PRIORITY=0

# set system filemax on supported OSes if this variable is set
# SYSMAXFILES=262144

# Asterisk allows full permissions by default, so set a umask, if you want
# restricted permissions.
#UMASK=022

# set max files open with ulimit. On linux systems, this will be automatically
# set to the system's maximum files open devided by two, if not set here.
# MAXFILES=32768

message() {
	if test -n "$TTY" && test "$TTY" != "no"; then
		echo "$1" >/dev/${TTY}
	fi
	if test -n "$SYSLOG"; then
		logger -p "${SYSLOG}.warn" -t safe_asterisk[$$] "$1"
	fi
	if test -n "$LOGFILE"; then
		echo "safe_asterisk[$$]: $1" >>"$LOGFILE"
	fi
}

# Check if Asterisk is already running.  If it is, then bug out, because
# starting safe_asterisk when Asterisk is running is very bad.
VERSION=`"${ASTSBINDIR}/asterisk" -nrx 'core show version' 2>/dev/null`
if test "`echo $VERSION | cut -c 1-8`" = "Asterisk"; then
	message "Asterisk is already running.  $0 will exit now."
	exit 1
fi

# since we're going to change priority and open files limits, we need to be
# root. if running asterisk as other users, pass that to asterisk on the command
# line.
# if we're not root, fall back to standard everything.
if test `id -u` != 0; then
	echo "Oops. I'm not root. Falling back to standard prio and file max." >&2
	echo "This is NOT suitable for large systems." >&2
	PRIORITY=0
	message "safe_asterisk was started by `id -n` (uid `id -u`)."
else
	if `uname -s | grep Linux >/dev/null 2>&1`; then
		# maximum number of open files is set to the system maximum
		# divided by two if MAXFILES is not set.
		if test -z "$MAXFILES"; then
			# just check if file-max is readable
			if test -r /proc/sys/fs/file-max; then
				MAXFILES=$((`cat /proc/sys/fs/file-max` / 2))
				# don't exceed upper limit of 2^20 for open
				# files on systems where file-max is > 2^21
				if test $MAXFILES -gt 1048576; then
					MAXFILES=1048576
				fi
			fi
		fi
		SYSCTL_MAXFILES="fs.file-max"
	elif `uname -s | grep Darwin /dev/null 2>&1`; then
		SYSCTL_MAXFILES="kern.maxfiles"
	fi


	if test -n "$SYSMAXFILES"; then
		if test -n "$SYSCTL_MAXFILES"; then
			sysctl -w $SYSCTL_MAXFILES=$SYSMAXFILES
		fi
	fi

	# set the process's filemax to whatever set above
	ulimit -n $MAXFILES

	if test ! -d "${ASTVARRUNDIR}"; then
		mkdir -p "${ASTVARRUNDIR}"
		chmod 770 "${ASTVARRUNDIR}"
	fi

fi

if test -n "$UMASK"; then
	umask $UMASK
fi

#
# Let Asterisk dump core
#
ulimit -c unlimited

#
# Don't fork when running "safely"
#
ASTARGS=""
if test -n "$TTY" && test "$TTY" != "no"; then
	if test -c /dev/tty${TTY}; then
		TTY=tty${TTY}
	elif test -c /dev/vc/${TTY}; then
		TTY=vc/${TTY}
	elif test "$TTY" = "9"; then  # ignore default if it was untouched
		# If there is no /dev/tty9 and not /dev/vc/9 we don't
		# necessarily want to die at this point. Pretend that
		# TTY wasn't set.
		TTY=
	else
		message "Cannot find specified TTY (${TTY})"
		exit 1
	fi
	if test -n "$TTY"; then
		ASTARGS="${ASTARGS} -vvvg"
		if test "$CONSOLE" != "no"; then
			ASTARGS="${ASTARGS} -c"
		fi
	fi
fi

if test ! -d "${RUNDIR}"; then
	message "${RUNDIR} does not exist, creating"
	if ! mkdir -p "${RUNDIR}"; then
		message "Unable to create ${RUNDIR}"
		exit 1
	fi
fi

if test ! -w "${DUMPDROP}"; then
	message "Cannot write to ${DUMPDROP}"
	exit 1
fi

#
# Don't die if stdout/stderr can't be written to
#
trap '' PIPE

#
# Run scripts to set any environment variables or do any other system-specific setup needed
#

if test -d "${ASTETCDIR}/startup.d"; then
	for script in "${ASTETCDIR}/startup.d/"*.sh; do
		if test -r "${script}"; then
			. "${script}"
		fi
	done
fi

run_asterisk()
{
	while :; do
		if test -n "$TTY" && test "$TTY" != "no"; then
			cd "${RUNDIR}"
			stty sane </dev/${TTY}
			nice -n $PRIORITY "${ASTSBINDIR}/asterisk" -f ${CLIARGS} ${ASTARGS} >/dev/${TTY} 2>&1 </dev/${TTY}
		else
			cd "${RUNDIR}"
			nice -n $PRIORITY "${ASTSBINDIR}/asterisk" -f ${CLIARGS} ${ASTARGS} >/dev/null 2>&1 </dev/null
		fi
		EXITSTATUS=$?
		message "Asterisk ended with exit status $EXITSTATUS"
		if test $EXITSTATUS -eq 0; then
			# Properly shutdown....
			message "Asterisk shutdown normally."
			exit 0
		elif test $EXITSTATUS -gt 128; then
			EXITSIGNAL=$((EXITSTATUS - 128))
			message "Asterisk exited on signal $EXITSIGNAL."
			if test -n "$NOTIFY"; then
				echo "Asterisk on $MACHINE exited on signal $EXITSIGNAL.  Might want to take a peek." | \
				mail -s "Asterisk on $MACHINE died (sig $EXITSIGNAL)" $NOTIFY
			fi
			if test -n "$EXEC"; then
				$EXEC
			fi

			PID=`cat ${ASTPIDFILE}`
			DATE=`date "+%Y-%m-%dT%H:%M:%S%z"`
			if test -f "${RUNDIR}/core.${PID}"; then
				mv "${RUNDIR}/core.${PID}" "${DUMPDROP}/core.`hostname`-$DATE" &
			elif test -f "${RUNDIR}/core"; then
				mv "${RUNDIR}/core" "${DUMPDROP}/core.`hostname`-$DATE" &
			fi
		else
			message "Asterisk died with code $EXITSTATUS."

			PID=`cat ${ASTPIDFILE}`
			DATE=`date "+%Y-%m-%dT%H:%M:%S%z"`
			if test -f "${RUNDIR}/core.${PID}"; then
				mv "${RUNDIR}/core.${PID}" "${DUMPDROP}/core.`hostname`-$DATE" &
			elif test -f "${RUNDIR}/core"; then
				mv "${RUNDIR}/core" "${DUMPDROP}/core.`hostname`-$DATE" &
			fi
		fi
		message "Automatically restarting Asterisk."
		sleep $SLEEPSECS
		if test "0$KILLALLMPG123" -gt 0; then
			pkill -9 mpg123
		fi
	done
}

if test -n "$ASTSAFE_FOREGROUND"; then
	run_asterisk
else
	run_asterisk &
fi
EOF
chown -R asterisk:asterisk /usr/sbin/safe_asterisk
chmod 777 /usr/sbin/safe_asterisk
./start_asterisk start
./install -n
clear
echo ""
cowsay "AUTOSTART FREEPBX ON BOOT"
echo ""
sleep 5
cat >> /etc/systemd/system/freepbx.service << EOF
[Unit]
Description=FreePBX VoIP Server
After=mariadb.service
 
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/sbin/fwconsole start -q
ExecStop=/usr/sbin/fwconsole stop -q
 
[Install]
WantedBy=multi-user.target

EOF
systemctl enable freepbx.service
ln -s '/etc/systemd/system/freepbx.service' '/etc/systemd/system/multi-user.target.wants/freepbx.service'
systemctl start freepbx
clear
echo ""
cowsay "DOWNLOAD AND INSTALL SOME FREEPBX MODULES"
echo ""
sleep 5
fwconsole ma downloadinstall cel
fwconsole ma downloadinstall configedit
fwconsole ma downloadinstall manager
fwconsole ma downloadinstall calendar
fwconsole ma downloadinstall timeconditions
fwconsole ma downloadinstall bulkhandler
fwconsole ma downloadinstall customcontexts
fwconsole ma downloadinstall ringgroups
fwconsole ma downloadinstall queues
fwconsole ma downloadinstall ivr
fwconsole ma downloadinstall asteriskinfo
fwconsole ma downloadinstall iaxsettings
fwconsole ma downloadinstall backup
fwconsole ma downloadinstall callforward
fwconsole ma downloadinstall announcement
fwconsole ma downloadinstall callrecording
fwconsole ma downloadinstall daynight
fwconsole ma downloadinstall extensionsettings
fwconsole ma downloadinstall featurecodeadmin
fwconsole ma downloadinstall recordings
fwconsole ma downloadinstall sipsettings
fwconsole ma downloadinstall soundlang
fwconsole ma downloadinstall voicemail
fwconsole r a
clear
echo ""
cowsay "INSTALLING SNGREP"
echo ""
sleep 5
cd /usr/src
echo '[irontec]
name=Irontec RPMs repository
baseurl=http://packages.irontec.com/centos/$releasever/$basearch/
' > /etc/yum.repos.d/irontec.repo
rpm --import http://packages.irontec.com/public.key
yum install sngrep -y
clear
echo ""
cowsay "INSTALLING WEBMIN"
echo ""
sleep 5
cd /usr/src
yum -y install perl perl-Net-SSLeay openssl perl-IO-Tty perl-Encode-Detect
wget http://prdownloads.sourceforge.net/webadmin/webmin-1.920-1.noarch.rpm
rpm -U webmin-1.920-1.noarch.rpm
clear
echo ""
cowsay "DONE! REBOOT IN 15 SECONDS"
echo ""
sleep 15
reboot
