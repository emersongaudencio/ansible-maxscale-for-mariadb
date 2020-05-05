#!/bin/bash
# Parameters configuration

verify_maxscale=`rpm -qa | grep maxscale`
if [[ $verify_maxscale == "maxscale"* ]]
then
echo "$verify_maxscale is installed!"
else
   ### PG Repo #####
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
