#!/bin/bash
# Parameters configuration

verify_maxscale=`rpm -qa | grep maxscale`
if [[ $verify_maxscale == "maxscale"* ]]
then
echo "$verify_maxscale is installed!"
else
   ##### FIREWALLD DISABLE #########################
   systemctl disable firewalld
   systemctl stop firewalld
   ######### SELINUX ###############################
   sed -ie 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
   # disable selinux on the fly
   /usr/sbin/setenforce 0

   ### clean yum cache ###
   rm -rf /etc/yum.repos.d/MariaDB.repo
   rm -rf /etc/yum.repos.d/mariadb.repo
   rm -rf /etc/yum.repos.d/mysql-community.repo
   rm -rf /etc/yum.repos.d/mysql-community-source.repo
   rm -rf /etc/yum.repos.d/percona-original-release.repo
   yum clean headers
   yum clean packages
   yum clean metadatas

   ####### PACKAGES ###########################
   # -------------- For RHEL/CentOS 7 --------------
   yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

   ### install pre-packages ####
   yum -y install screen nload bmon openssl libaio rsync snappy net-tools wget nmap htop dstat sysstat

   ### MaxScale Setep ####
   curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash
   yum -y install maxscale

   ### Installation MARIADB via yum ####
   yum -y install MariaDB-client

   ### Percona #####
   ### https://www.percona.com/doc/percona-server/LATEST/installation/yum_repo.html
   yum install https://repo.percona.com/yum/percona-release-latest.noarch.rpm -y
   yum -y install percona-toolkit sysbench

   ##### CONFIG PROFILE #############
   echo ' ' >> /etc/profile
   echo '# maxscale' >> /etc/profile
   echo 'if [ $USER = "maxscale" ]; then' >> /etc/profile
   echo '  if [ $SHELL = "/bin/bash" ]; then' >> /etc/profile
   echo '    ulimit -u 16384 -n 65536' >> /etc/profile
   echo '  else' >> /etc/profile
   echo '    ulimit -u 16384 -n 65536' >> /etc/profile
   echo '  fi' >> /etc/profile
   echo 'fi' >> /etc/profile

   mkdir -p /etc/systemd/system/maxscale.service.d/
   echo ' ' > /etc/systemd/system/maxscale.service.d/limits.conf
   echo '# maxscale' >> /etc/systemd/system/maxscale.service.d/limits.conf
   echo '[Service]' >> /etc/systemd/system/maxscale.service.d/limits.conf
   echo 'LimitNOFILE=102400' >> /etc/systemd/system/maxscale.service.d/limits.conf
   systemctl daemon-reload
fi
