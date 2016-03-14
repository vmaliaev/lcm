apt-get install git -y

#mysql -e "DROP DATABASE foreman"; mysql -e "DROP USER 'foreman'@'localhost'";

git clone https://github.com/vmaliaev/lcm

cp -r ./lcm/foreman_ext /etc/fuel/plugins/fuel-plugin-lcm-2.0/puppet/modules/ ; cp ./lcm/foreman_main.pp /etc/fuel/plugins/fuel-plugin-lcm-2.0/puppet/manifests/

notify {'run apipie': notify => Foreman::Rake["$::foreman::apipie_task"], }

puppet apply --modulepath=/etc/fuel/plugins/fuel-plugin-lcm-2.0/puppet/modules:/etc/puppet/modules /etc/fuel/plugins/fuel-plugin-lcm-2.0/puppet/manifests/foreman_main.pp
