#!/bin/bash

# Preparing new environment for att, upload repos, reinstall plugin, recreate env

if [ `ls * | grep -c fuel-plugin-lcm-1.0-1.0.0-1.noarch.rpm` -eq 0 ] ; then echo "ERROR: Change directory on containted fuel-plugin-lcm-1.0-1.0.0-1.noarch.rpm"; echo "Exiting..." ; exit 1 ; fi



echo "Preparing new ENV"
echo "-----------------"

echo "Deleting all environments:"
fuel nodes list
for i in `fuel env | grep  -v -e '\-\-\-' -e 'id' | awk '{print $1}'` ; do fuel env --env-id ${i} delete ; done

echo "Deleting plugin:"
fuel plugins --remove fuel-plugin-lcm==1.0.0

echo "Installing plugin:"
fuel plugins --install fuel-plugin-lcm-1.0-1.0.0-1.noarch.rpm

echo "Creating env --name AUTOENV:"
fuel env create --name AUTOENV --rel 2 --net-segment-type vlan

echo "Copying targetimages:"
cp /var/www/nailgun/targetimages/copy/* /var/www/nailgun/targetimages/
fuel env | grep AUTOENV | awk '{print $1}'
cd /var/www/nailgun/targetimages
export e=`fuel env | grep AUTOENV | awk '{print $1}'`; for i in `ls | grep env` ; do a=`echo $i | sed -E "s/env_.+_(ubuntu.*)/env_${e}_\1/"` ; echo $a ; mv $i $a ; done
cd -

echo "Upload ATT repos:"
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


