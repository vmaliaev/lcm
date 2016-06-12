#!/bin/bash

# Functions
function install_fpb() {
#  apt-get -y git easy_pip ....
#  easy_pip install
}


# BODY
# Preparing new environment for att, upload repos, reinstall plugin, recreate env

#install_fpb #Uncomment it on new environment

if [ `ls * | grep -c fuel-plugin-lcm-1.0-1.0.0-1.noarch.rpm` -eq 0 ] ; then echo "ERROR: Change directory to containted fuel-plugin-lcm-1.0-1.0.0-1.noarch.rpm"; echo "Exiting..." ; exit 1 ; fi



echo -e "\nPreparing new ENV"
echo "-----------------"

echo -e "\nArchiving targetimages:"
mkdir -p /var/www/nailgun/targetimages/copy
rm -f /var/www/nailgun/targetimages/copy/*
cd /var/www/nailgun/targetimages
env_no=`ls | grep yaml | head -1 | cut -d"_" -f2`
mv /var/www/nailgun/targetimages/env_${env_no}_* /var/www/nailgun/targetimages/copy/
cd -

echo -e "\nDeleting all environments:"
fuel nodes list
for i in `fuel env | grep  -v -e '\-\-\-' -e 'id' | awk '{print $1}'` ; do fuel env --env-id ${i} delete --force ; done

sleep 10

echo -e "\nDeleting plugin:"
fuel plugins --remove fuel-plugin-lcm==1.0.0

echo -e "\nInstalling plugin:"
fuel plugins --install fuel-plugin-lcm-1.0-1.0.0-1.noarch.rpm

echo -e "\nCreating env --name AUTOENV:"
fuel env create --name AUTOENV --rel 2 --net-segment-type vlan

echo -e "\nCopying targetimages:"
cp /var/www/nailgun/targetimages/copy/* /var/www/nailgun/targetimages/
fuel env | grep AUTOENV | awk '{print $1}'
cd /var/www/nailgun/targetimages
export e=`fuel env | grep AUTOENV | awk '{print $1}'`; for i in `ls | grep env` ; do a=`echo $i | sed -E "s/env_.+_(ubuntu.*)/env_${e}_\1/"` ; echo $a ; mv $i $a ; done
cd -

echo -e "\nUpload ATT repos:"
fuel settings --env-id $e download --dir ~/
sed "/service_user/i \\
      - name: extra-0\\
        priority: 1150\\
        section: main\\
        suite: trusty\\
        type: deb\\
        uri: http://172.18.82.139/percona/\\
      - name: extra-1\\
        priority: 1160\\
        section: main\\
        suite: mos7.0\\
        type: deb\\
        uri: http://172.18.82.139/mos-7.0/\\
      - name: extra-2\\
        priority: 1170\\
        section: main\\
        suite: trusty\\
        type: deb\\
        uri: http://172.18.82.139/infra-mirror-9.0-master/\\
" -i ~/settings_${e}.yaml

fuel settings --env-id $e upload --dir ~/

echo -e "\nfuel node --env-id=${e} --node-id=2,2,2 --provision"

echo -e "\nFINISH, I will be waiting about 7 minutes for discovered nodes and will echo a message to provision."
#sleep 420
# Waiting nodes to back online:
while [ `fuel node | grep discover | awk '{print $1}' | wc -l` -lt 3 ] ; do
  sleep 5
done

# Creating launch line:
ips=""
if [ `fuel node | grep discover | awk '{print $1}' | wc -l` -gt 2 ] ; then
  for i in `fuel node | awk /discover/'{print $1}'` ; do ips="${ips}$i,"; done ;
fi

ips=`echo ${ips} | rev | cut -c 2- | rev`

fuel node
echo -e "\nfuel node --env-id=${e} --node-id=${ips} --provision; sleep 300; fuel node --env-id=${e} --node-id=${ips} --deploy"
echo 'mco rpc execute_shell_command execute cmd="echo sudo -i>>/var/lib/fuel/.profile"'


