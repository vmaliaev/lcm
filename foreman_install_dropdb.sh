apt-get install git -y

#mysql -e "DROP DATABASE foreman"; mysql -e "DROP USER 'foreman'@'localhost'";

git clone https://github.com/vmaliaev/lcm

a=`ls /etc/fuel/plugins/`
#cp -r ./lcm/foreman_ext /etc/fuel/plugins/fuel-plugin-lcm-2.0/puppet/modules/ ; cp ./lcm/foreman_main.pp /etc/fuel/plugins/fuel-plugin-lcm-2.0/puppet/manifests/
#cp -r ./lcm/deployment_scripts/puppet/modules/plugin_lcm/manifests/foreman_ext.pp /etc/fuel/plugins/${a}/puppet/modules/plugin_lcm/manifests/ 
cp ./lcm/foreman_main.pp /etc/fuel/plugins/${a}/puppet/manifests/

puppet apply --modulepath=/etc/fuel/plugins/fuel-plugin-lcm-2.0/puppet/modules:/etc/puppet/modules /etc/fuel/plugins/fuel-plugin-lcm-2.0/puppet/manifests/foreman_main.pp
