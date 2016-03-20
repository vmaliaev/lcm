#
notice('PLUGIN: fuel-plugin-lcm/foreman_main.pp')

$roles                   = hiera('roles')
$network_metadata        = hiera('network_metadata')
$lcm_hiera_values        = hiera('fuel-plugin-lcm')
#$fqdn			 = hiera('fqdn') # Change to $::fqdn
#$lower_fqdn 		 = downcase($::fqdn)




$lcm_nodes_array         = get_nodes_hash_by_roles($network_metadata, ['primary-lcm', 'lcm'])

$dbname			 = 'foreman'
$db_user		 = $lcm_hiera_values['db_user']
$db_pass		 = $lcm_hiera_values['db_pass'] #TODO: add password generator


#$mariadb_root_password   = $lcm_hiera_values['metadata']['mariadb_root_password']

$foreman_user		  = $lcm_hiera_values['foreman_user']
$foreman_password         = $lcm_hiera_values['foreman_password']
$oauth_consumer_key	  = $lcm_hiera_values['oauth_consumer_key'] #TODO: add random function
$oauth_consumer_secret	  = $lcm_hiera_values['oauth_consumer_secret'] #TODO: add random secret

$foreman_base_url	  = $lcm_hiera_values['foreman_base_url'] #TODO: add $( hostname -f)

# TODO: Change the following resource parameters or move it to init.pp !!!!!!!
mysql::db { $dbname:
 user     => $db_user,
 password => $db_pass,
 host     => localhost,
 grant    => ['ALL'],
}
#  ::mysql::db { $dbname:
#    user     => $::foreman::db_username,
#    password => $::foreman::db_password,
#  }

concat::fragment { 'Apache ports header1':
    target  => '/etc/apache2/ports.conf', #""$ports_file,
    content => "Listen 8140\n",
}

class { '::foreman':
  db_type => mysql,
  db_host => localhost, #$fqdn,
  db_port => 3306,
  db_manage => false, #true,
  db_adapter => mysql2,
  db_database => $dbname,
  db_username => $db_user,
  db_password => $db_pass,
  admin_username => $foreman_user,
  admin_password => $foreman_password,
  authentication => true,
  oauth_active => true,
  oauth_map_users => true,
  oauth_consumer_key => $oauth_consumer_key,
  oauth_consumer_secret => $oauth_consumer_secret,
  passenger	=> true,
  apipie_task => "apipie:cache:index",
  app_root	=> "/usr/share/foreman",
  passenger_prestart	=> true,
  passenger_min_instances	=> "1",
  passenger_start_timeout	=> "600",
  environment=> production,
  user => foreman, #Clarification
  group => foreman, #Clarification
  puppetrun => true,
}
# validate_re($environment, ['^productio$', '^smtp$'], "email_delivery_method can be either sendmail or smtp, not")

class { '::plugin_lcm::foreman_ext':
  db_type => mysql,
  db_host => localhost, #$fqdn,
  db_port => 3306,
  db_manage => false, #true,
  db_adapter => mysql2,
  db_database => $dbname,
  db_username => $db_user,
  db_password => $db_pass,
  admin_username => $foreman_user,
  admin_password => $foreman_password,
  authentication => true,
  oauth_active => true,
  oauth_map_users => true,
  oauth_consumer_key => $oauth_consumer_key,
  oauth_consumer_secret => $oauth_consumer_secret,
  passenger	=> true,
  apipie_task => "apipie:cache:index",
  app_root	=> "/usr/share/foreman",
  passenger_prestart	=> true,
  passenger_min_instances	=> "1",
  passenger_start_timeout	=> "600",
  environment=> production,
  user => foreman, #Clarification
  group => foreman, #Clarification
  puppetrun => true,
}



#class { '::foreman::puppetmaster':
#foreman_user => 'admin',
#foreman_password => 'changemea',
#passenger => true,
#}

class { '::foreman_proxy':
  plugin_version => absent,
  ssl => true,
  http_port => 8000,
  ssl_port => 8443,
  puppetrun => true,
  tftp => false,
  dhcp => false,
  dns => false,
  bmc => false,
  realm => false,
  register_in_foreman => true,
  foreman_base_url => "https://$fqdn", #$foreman_base_url,
  oauth_consumer_key => $oauth_consumer_key,
  oauth_consumer_secret => $oauth_consumer_secret,
  registered_name => $fqdn,
  registered_proxy_url => "https://${fqdn}:8443", # Change to lower_fqdn
  oauth_effective_user => $foreman_user,
  dir => "/usr/share/foreman-proxy",
  user => foreman-proxy,
 
}


