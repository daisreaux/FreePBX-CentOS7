#!/bin/bash
clear
yum install cowsay -y
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
yum -y install php56w php56w-pdo php56w-mysql php56w-mbstring php56w-pear php56w-process php56w-xml php56w-opcache php56w-ldap php56w-intl php56w-soap
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
cowsay "MENU SELECT (You are using Asterisk 16, enable format_mp3, res_config_mysql, app_macro)"
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

EOF
chown -R asterisk:asterisk /usr/sbin/safe_asterisk
chmod 755 /usr/sbin/safe_asterisk
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
yum -y install perl perl-Net-SSLeay openssl perl-IO-Tty perl-Encode-Detect
wget http://prdownloads.sourceforge.net/webadmin/webmin-1.920-1.noarch.rpm
rpm -U webmin-1.920-1.noarch.rpm
clear
echo ""
cowsay "DONE! REBOOT IN 15 SECONDS"
echo ""
sleep 15
reboot
