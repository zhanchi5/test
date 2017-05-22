#!/bin/bash
#------------------------------------------------------------------------------------------------------------
USERNAME="sysinfo"
SCRIPTS_DIR="/home/${USERNAME}/scripts"
INI_CONFIG="${SCRIPTS_DIR}/scripts.ini"
UPD_TIME=30
#------------------------------------------------------------------------------------------------------------
RED='\033[0;31m'
BLU='\033[0;34m'
NCC='\033[0m'
GRE='\033[0;32m'
#------------------------------------------------------------------------------------------------------------
# Find location of scrit
BASEDIR=`dirname $0`
PROJECT_PATH=`cd $BASEDIR; pwd`
#------------------------------------------------------------------------------------------------------------
# Check the script is being run by root
if [ "$(id -u)" != "0" ]; then
	echo -e "${RED}This script must be run as root!${NCC}"
	sudo $PROJECT_PATH/install.sh; exit 0;
fi
#------------------------------------------------------------------------------------------------------------
# Add newuser for syinfo system
echo -e "${GRE}Using path: ${PROJECT_PATH} ${NCC}"
echo -e "${GRE}Creating user sysinfo ...${NCC}"
useradd -m -c "User for web-sysinfo" $USERNAME
passwd -d $USERNAME
#------------------------------------------------------------------------------------------------------------
# Locate TCPDUMP and TIMEOUT
c1=$(whereis tcpdump | awk -F " " '{ print $2 }')
c2=$(whereis timeout | awk -F " " '{ print $2 }')
cs=${SCRIPTS_DIR}/*
#------------------------------------------------------------------------------------------------------------
# Added sudo rules to /etc/sudoers for sysinfo user
echo -e "${GRE}Trying to add record to /etc/sudoers ...${NCC}"
printf "\n# User for web-sysinfo [!]\n ${USERNAME} ALL=NOPASSWD: $c1, $c2, $cs\n" >> /etc/sudoers
if [ $? != "0" ]; then
	echo -e "${RED}Couldn't change file: /etc/sudoers${NCC}"
fi
#------------------------------------------------------------------------------------------------------------
# Prepare directories for scripts and web-pages
echo -e "${GRE}Starting to copy scripts to ${SCRIPTS_DIR} ...${NCC}"
mkdir -p $SCRIPTS_DIR/data
mkdir -p /var/www/html/sysinfo
touch $INI_CONFIG
#------------------------------------------------------------------------------------------------------------
# [1] LOADAVG
cp -f $PROJECT_PATH/loadavg.sh $SCRIPTS_DIR/loadavg.sh
printf "loadavg=${SCRIPTS_DIR}/loadavg.sh\n" >> $INI_CONFIG
# [2] IOSTAT
cp -f $PROJECT_PATH/iostat.sh $SCRIPTS_DIR/iostat.sh
printf "iostat=\"cat ${SCRIPTS_DIR}/data/print_iostat\"\n" >> $INI_CONFIG
# [3] NETINF
cp -f $PROJECT_PATH/netinf.sh $SCRIPTS_DIR/netinf.sh
printf "netinf=\"cat ${SCRIPTS_DIR}/data/print_netinf\"\n" >> $INI_CONFIG
# [4] TOPTLK
#cp -f $PROJECT_PATH/toptlk.sh $SCRIPTS_DIR/toptlk.sh
cp -f $PROJECT_PATH/dpkt_test.py  $SCRIPTS_DIR/dpkt_test.py 
printf "toptlk=\"cat ${SCRIPTS_DIR}/data/top_tlk\"\n" >> $INI_CONFIG
# [5] NETCON
cp -f $PROJECT_PATH/netcon.sh $SCRIPTS_DIR/netcon.sh
printf "netcon=\"cat ${SCRIPTS_DIR}/data/print_netcon\"\n" >> $INI_CONFIG
# [6] CPUINF
cp -f $PROJECT_PATH/cpuinf.sh $SCRIPTS_DIR/cpuinf.sh
printf "cpuinf=\"cat ${SCRIPTS_DIR}/data/print_cpuinf\"\n" >> $INI_CONFIG
# [7] DISKST
cp -f $PROJECT_PATH/diskst.sh $SCRIPTS_DIR/diskst.sh
printf "diskst=\"cat ${SCRIPTS_DIR}/data/print_diskst\"\n" >> $INI_CONFIG
# [E]
chown -R sysinfo:sysinfo $SCRIPTS_DIR/
chmod +x $SCRIPTS_DIR/*
#------------------------------------------------------------------------------------------------------------
# Crontab
echo -e "${GRE}Adding crontab for ${USERNAME} ...${NCC}"
crontab -l -u $USERNAME | cat - $PROJECT_PATH/automatic.cron | crontab -u $USERNAME -
#------------------------------------------------------------------------------------------------------------
# Setup scripts with special files
echo -e "${GRE}Prepare scripts ...${NCC}"
sudo $SCRIPTS_DIR/netinf.sh $SCRIPTS_DIR/data/curr_netinf
#------------------------------------------------------------------------------------------------------------
echo -e "${GRE}Installing tools, apache2+php and nginx ...${NCC}"
apt install -y sysstat lynx apache2 libapache2-mod-php
systemctl stop apache2
apt install -y nginx
#------------------------------------------------------------------------------------------------------------
echo -e "${GRE}Starting to copy configuration files${NCC}"
cp -f $PROJECT_PATH/nginx-default.conf /etc/nginx/sites-enabled/default
cp -f $PROJECT_PATH/apache-ports.conf /etc/apache2/ports.conf
cp -f $PROJECT_PATH/apache-default.conf /etc/apache2/sites-enabled/000-default.$
cp -f $PROJECT_PATH/index.html /var/www/html/index.html
cp -f $PROJECT_PATH/index.php /var/www/html/index.php
cp -f $PROJECT_PATH/phpinfo.php /var/www/html/phpinfo.php
cp -f $PROJECT_PATH/sysinfo.php /var/www/html/sysinfo/index.php
#------------------------------------------------------------------------------------------------------------
sed -i "1 i <?php \$iniFile=\"${INI_CONFIG}\"; \$updateTime=${UPD_TIME}; ?>" /var/www/html/sysinfo/index.php
#------------------------------------------------------------------------------------------------------------
echo -e "${GRE}Restarting servers ... ${NCC}"
systemctl start apache2
systemctl restart nginx
#------------------------------------------------------------------------------------------------------------
# Restart scripts to collect inforamation from setup
echo -e "${GRE}Restarting scripts ... ${NCC}"
sudo $SCRIPTS_DIR/iostat.sh $SCRIPTS_DIR/data/print_iostat 
#sudo $SCRIPTS_DIR/data/print_cpuinf
sudo $SCRIPTS_DIR/netinf.sh
#sudo $SCRIPTS_DIR/toptlk.sh $SCRIPTS_DIR/data/print_toptlk &
sudo $SCRIPTS_DIR/netcon.sh
sudo $SCRIPTS_DIR/diskst.sh
sudo python $SCRIPTS_DIR/dpkt_test.py $SCRIPTS_DIR/data/top_tlk &
#------------------------------------------------------------------------------------------------------------
netstat -nlpt
echo -e "${GRE}END OF SCRIPT${NCC}\n"
#------------------------------------------------------------------------------------------------------------
exit 0
