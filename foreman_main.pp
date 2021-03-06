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

include ::plugin_lcm
$lcm_apache_ports         = $::plugin_lcm::lcm_apache_ports
$lcm_hiera_values         = $::plugin_lcm::lcm_hiera_values

$dbname                   = 'foreman'
$db_user                  = 'foreman'
$db_pass                  = $lcm_hiera_values['metadata']['foreman_db_password']

$foreman_user             = $lcm_hiera_values['foreman_user']
$foreman_password         = $lcm_hiera_values['foreman_password']
$oauth_consumer_key       = pick($lcm_hiera_values['oauth_consumer_key'], cache_data('foreman_cache_data', 'oauth_consumer_key', random_password(32)))
$oauth_consumer_secret    = pick($lcm_hiera_values['oauth_consumer_secret'], cache_data('foreman_cache_data', 'oauth_consumer_secret', random_password(32)))

$foreman_base_url         = pick($lcm_hiera_values['foreman_base_url'], "https://${fqdn}")
$oauth_effective_user     = $lcm_hiera_values['oauth_effective_user']

$tftp                     = $lcm_hiera_values['tftp']
$dhcp                     = $lcm_hiera_values['dhcp']
$dns                      = $lcm_hiera_values['dns']
$bmc                      = $lcm_hiera_values['bmc']
$db_host                  = 'localhost'

########################################################################
#### Check If it is a custom cert case or not
$own_ssl_certificate      = $lcm_hiera_values['own_ssl_certificate']
$ssl_foreman_private_key  = $lcm_hiera_values['ssl_foreman_cert_private_key'][content]
$ssl_foreman_cert         = $lcm_hiera_values['ssl_foreman_cert'][content]
$ssl_crl_location         = $lcm_hiera_values['ssl_crl_location'][content]
$foreman_cert_files       = ["foreman_cert.key","foreman_cert.crt","foreman_crl.crl",]


if ($own_ssl_certificate) and ($ssl_foreman_private_key != "") and ($ssl_foreman_cert != "") {

### Create /etc/foreman/ssl/
  file {'/etc/foreman/ssl':
    ensure => 'directory',
    owner  => 'foreman',
    group  => 'puppet',
    mode   => '0750',
  }

### create key,cert,crl
  
  file { $foreman_cert_files:
    ensure  => 'file',
    owner   => 'foreman',
    group   => 'puppet',
    mode    => '640',
    path    => '/etc/foreman/ssl/',
    content => [$ssl_foreman_private_key, $ssl_foreman_cert, $ssl_crl_location], 
    require => File['/etc/foreman/ssl'],
  }

### find & reassign key,cert,crl variable to new ones

  $server_ssl_key       = '/etc/foreman/ssl/foreman_cert.key'
  $server_ssl_cert      = '/etc/foreman/ssl/foreman_cert.crt'
  $server_ssl_crl       = '/etc/foreman/ssl/foreman_crl.crl'
  $server_ssl_certs_dir = '/etc/foreman/ssl/'

}
########################################################################


$foreman_proxy_dir        = '/usr/share/foreman-proxy'

file { $foreman_proxy_dir:
  owner   => 'foreman-proxy',
  group   => 'foreman-proxy',
  recurse => true,
  require => Class['::foreman_proxy'],
}

mysql::db { $dbname:
  user     => $db_user,
  password => $db_pass,
  host     => $db_host,
  grant    => ['ALL'],
}

apache::listen { $lcm_apache_ports: }

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
  oauth_consumer_key      => $oauth_consumer_key,
  oauth_consumer_secret   => $oauth_consumer_secret,
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
  oauth_consumer_key      => $oauth_consumer_key,
  oauth_consumer_secret   => $oauth_consumer_secret,
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
  puppetrun_provider    => 'customrun',
  customrun_cmd         => '/usr/bin/puppet',
  customrun_args        => 'kick --host',
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
  dir                   => $foreman_proxy_dir,
  user                  => foreman-proxy, # Need clarification
  trusted_hosts         => [],
}
