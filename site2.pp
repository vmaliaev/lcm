# rename to foreman_main.pp
mysql::db { foreman:
 user     => foreman,
 password => changeme,
 host     => localhost,
 grant    => ['ALL'],
}

class { '::foreman':
  db_type => mysql,
  db_host => localhost,
  db_port => 3306,
  db_manage => false, #true,
  db_adapter => mysql2,
  db_database => foreman,
  db_username => foreman,
  db_password => 'changeme',
  admin_username => admin,
  admin_password => 'changemea',
  authentication => true,
  oauth_active => true,
  oauth_map_users => true,
#  oauth_consumer_key => WvZpMupBEGZPj6RXXZBprvUKg6kSNM5e,
#  oauth_consumer_secret => "EiwMYSN78wKxQETrqB7rhCWBn9HcXV3x",
  passenger	=> true,
  apipie_task => "apipie:cache:index",
  app_root	=> "/usr/share/foreman",
  passenger_prestart	=> true,
  passenger_min_instances	=> "1",
  passenger_start_timeout	=> "600",
  environment=> production,
  user => foreman,
  group => foreman,
  puppetrun => true,
}
# validate_re($environment, ['^productio$', '^smtp$'], "email_delivery_method can be either sendmail or smtp, not")
class { '::foreman_wrapper':
  db_type => mysql,
  db_host => localhost,
  db_port => 3306,
  db_manage => false, #true,
  db_adapter => mysql2,
  db_database => foreman,
  db_username => foreman,
  db_password => 'changeme',
  admin_username => admin,
  admin_password => 'changemea',
  authentication => true,
  oauth_active => true,
  oauth_map_users => true,
  oauth_consumer_key => WvZpMupBEGZPj6RXXZBprvUKg6kSNM5e,
  oauth_consumer_secret => "EiwMYSN78wKxQETrqB7rhCWBn9HcXV3x",
  passenger	=> true,
  apipie_task => "apipie:cache:index",
  app_root	=> "/usr/share/foreman",
  passenger_prestart	=> true,
  passenger_min_instances	=> "1",
  passenger_start_timeout	=> "600",
  environment=> production,
  user => foreman,
  group => foreman,
  puppetrun => true,
}




#foreman_config_entry { 'db_pending_migration':
#     value => false,
#     dry   => true,
#   } ~>
#foreman::rake { 'db:migrate':
# user     => 'root',
# app_root => '/usr/share/foreman',
#}~> 

#foreman::rake { 'apipie:cache':
#}~>

class { '::foreman::puppetmaster':
foreman_user => 'admin',
foreman_password => 'changemea',
#passenger => true,
}

class { '::foreman_proxy':
  tftp => false,
  plugin_version => absent,
  ssl => true,
  http_port => 8000,
  ssl_port => 8443,
  puppetrun => true,
  dhcp => false,
  dns => false,
  bmc => false,
  realm => false,
  register_in_foreman => true,
  foreman_base_url => "https://node-15.domain.tld",
#  oauth_consumer_key => WvZpMupBEGZPj6RXXZBprvUKg6kSNM5e,
#  oauth_consumer_secret => "EiwMYSN78wKxQETrqB7rhCWBn9HcXV3x",
  registered_name => 'node-15.domain.tld',
  registered_proxy_url => "https://node-15.domain.tld:8443",
  oauth_effective_user => admin,
  dir => "/usr/share/foreman-proxy",
  user => foreman-proxy,
 
}

