#    Copyright 2016 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

notice('PLUGIN: fuel-plugin-lcm/foreman_main.pp')

#$roles                    = hiera('roles')
#$network_metadata         = hiera('network_metadata')
#$lcm_nodes_array          = get_nodes_hash_by_roles($network_metadata, ['primary-lcm', 'lcm'])

include ::plugin_lcm
$lcm_apache_ports         = $::plugin_lcm::lcm_apache_ports
$lcm_hiera_values         = $::plugin_lcm::lcm_hiera_values #hiera('fuel-plugin-lcm')

$dbname                   = 'foreman'
$db_user                  = $lcm_hiera_values['db_user'] #TODO: add pick from foreman params.pp $::foreman::db_username 
$db_pass                  = $lcm_hiera_values['db_pass'] #TODO: add pick from foreman params.pp $::foreman::db_password

$foreman_user             = $lcm_hiera_values['foreman_user']
$foreman_password         = $lcm_hiera_values['foreman_password']
$oauth_consumer_key       = $lcm_hiera_values['oauth_consumer_key'] #TODO: add random function
$oauth_consumer_secret    = $lcm_hiera_values['oauth_consumer_secret'] #TODO: add random secret

$foreman_base_url         = pick($lcm_hiera_values['foreman_base_url'], "https://${fqdn}")
$oauth_effective_user     = $lcm_hiera_values['oauth_effective_user']

$tftp                     = $lcm_hiera_values['tftp']
$dhcp                     = $lcm_hiera_values['dhcp']
$dns                      = $lcm_hiera_values['dns']
$bmc                      = $lcm_hiera_values['bmc']
$db_host                  = 'localhost'

mysql::db { $dbname:
  user     => $db_user,
  password => $db_pass,
  host     => $db_host,
  grant    => ['ALL'],
}

apache::listen { $lcm_apache_ports:
}

#TODO: Refactor the following classes. Involve create_resources()
class { '::foreman':
  db_type                 => mysql,
  db_host                 => $db_host,
  db_port                 => 3306,
  db_manage               => false,
  db_adapter              => mysql2,
  db_database             => $dbname,
  db_username             => $db_user,
  db_password             => $db_pass,
  admin_username          => $foreman_user,
  admin_password          => $foreman_password,
  authentication          => true,
  oauth_active            => true,
  oauth_map_users         => true,
  oauth_consumer_key      => $oauth_consumer_key, #TODO: add randomly generated key
  oauth_consumer_secret   => $oauth_consumer_secret, #TODO: add randomly generated secret
  passenger               => true,
  apipie_task             => 'apipie:cache:index',
  app_root                => '/usr/share/foreman',
  passenger_prestart      => true,
  passenger_min_instances => '1',
  passenger_start_timeout => '600',
  environment             => production,
  user                    => foreman, # Need clarification
  group                   => foreman, # Need clarification
  puppetrun               => true,
}

class { '::plugin_lcm::foreman_ext':
  db_type                 => mysql,
  db_host                 => $db_host,
  db_port                 => 3306,
  db_manage               => false,
  db_adapter              => mysql2,
  db_database             => $dbname,
  db_username             => $db_user,
  db_password             => $db_pass,
  admin_username          => $foreman_user,
  admin_password          => $foreman_password,
  authentication          => true,
  oauth_active            => true,
  oauth_map_users         => true,
  oauth_consumer_key      => $oauth_consumer_key, #TODO: add randomly generated key
  oauth_consumer_secret   => $oauth_consumer_secret, #TODO: add randomly generated secret
  passenger               => true,
  apipie_task             => 'apipie:cache:index',
  app_root                => '/usr/share/foreman',
  passenger_prestart      => true,
  passenger_min_instances => '1',
  passenger_start_timeout => '600',
  environment             => production,
  user                    => foreman, #Clarification
  group                   => foreman, #Clarification
  puppetrun               => true,
}

class { '::foreman_proxy':
  plugin_version        => absent,
  ssl                   => true,
  http_port             => 8000,
  ssl_port              => 8443,
  puppetrun             => true,
  tftp                  => $tftp,
  dhcp                  => $dhcp,
  dns                   => $dns,
  bmc                   => $bmc,
  realm                 => false, # Do we really need it?
  register_in_foreman   => true,
  foreman_base_url      => $foreman_base_url,
  oauth_consumer_key    => $oauth_consumer_key,
  oauth_consumer_secret => $oauth_consumer_secret,
  registered_name       => $fqdn,
  registered_proxy_url  => "https://${fqdn}:8443", # TODO: Change to lower_fqdn
  oauth_effective_user  => $oauth_effective_user,
  dir                   => '/usr/share/foreman-proxy',
  user                  => foreman-proxy, # Need clarification
}
