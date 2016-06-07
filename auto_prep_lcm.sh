#!/bin/bash

# Preparing new environment for att, upload repos, reinstall plugin, recreate env

if [ `ls * | grep -c fuel-plugin-lcm-1.0-1.0.0-1.noarch.rpm` -eq 0 ] ; then echo "ERROR: Change directory on containted fuel-plugin-lcm-1.0-1.0.0-1.noarch.rpm"; echo "Exiting..." ; exit 1 ; fi



echo -e "\nPreparing new ENV"
echo "-----------------"

echo -e "\nDeleting all environments:"
fuel nodes list
for i in `fuel env | grep  -v -e '\-\-\-' -e 'id' | awk '{print $1}'` ; do fuel env --env-id ${i} delete ; done

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
      - name: mos-aic\\
        priority: 1160\\
        section: main\\
        suite: mos7.0\\
        type: deb\\
        uri: http://10.20.0.2:8080/aic-3.0.1/mos-7.0/\\
      - name: system-9-0\\
        priority: 1170\\
        section: main\\
        suite: trusty\\
        type: deb\\
        uri: http://10.20.0.2:8080/aic-3.0.1/infra-mirror-9.0-master/\\
      - name: percona\\
        priority: 2150\\
        section: main\\
        suite: trusty\\
        type: deb\\
        uri: http://repo.percona.com/apt" -i ~/settings_${e}.yaml

fuel settings --env-id $e upload --dir ~/

echo -e "\nfuel node --env-id=${e} --node-id=2,2,2 --provision"

echo -e "\nFINISH, I will be waiting 3 minutes for discovered nodes and will echo a message to provision."

sleep 180

ips=""
if [ `fuel node | grep discover | awk '{print $1}' | wc -l` -gt 2 ] ; then
  for i in `fuel node | awk /discover/'{print $1}'` ; do ips="${ips}$i,"; done ;
fi

echo ${ips} | rev | cut -c 2- | rev

fuel node
echo -e "\nfuel node --env-id=${e} --node-id=${ips} --provision"

