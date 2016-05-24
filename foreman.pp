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

notice('MODULAR: fuel-plugin-lcm/foreman.pp')

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

$foreman_proxy_dir        = '/usr/share/foreman-proxy'

# We have to remove this package from catalog
# because it conflicts with percona packages
Package<| title == 'mysql_client' |> {
  ensure => absent,
}

Package<| title == 'mysql-server' |> {
  ensure => absent,
}

file { $foreman_proxy_dir:
  owner   => 'foreman-proxy',
  group   => 'foreman-proxy',
  recurse => true,
  require => Class['::foreman_proxy'],
}

apache::listen { $lcm_apache_ports: }

########################################################################
# Create common hash
$common_foreman_hash = {
  '::foreman' => {
    custom_repo             => true,
    db_type                 => mysql,
    db_host                 => $db_host,
    db_port                 => 3306,
    db_manage               => true,
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
    logging_level           => 'debug',
  },
}
#### Check If it is a custom cert case or not
$own_ssl_certificate          = $lcm_hiera_values['own_ssl_certificate']
if $own_ssl_certificate {
  $ssl_foreman_private_key      = $lcm_hiera_values['ssl_foreman_cert_private_key'][content]
  $ssl_foreman_private_key_name = $lcm_hiera_values['ssl_foreman_cert_private_key'][name]
  $ssl_foreman_cert             = $lcm_hiera_values['ssl_foreman_cert'][content]
  $ssl_foreman_cert_name        = $lcm_hiera_values['ssl_foreman_cert'][name]
  $ssl_crl_location             = $lcm_hiera_values['ssl_crl_location'][content]
  $ssl_crl_location_name        = $lcm_hiera_values['ssl_crl_location'][name]
  $foreman_cert_dir             = '/etc/foreman/ssl'
  
  if ($ssl_foreman_private_key != "") and ($ssl_foreman_cert != "") {
    file { $foreman_cert_dir:
      ensure => 'directory',
      owner  => 'foreman',
      group  => 'puppet',
      mode   => '0750',
    }

    File <| (title == $ssl_foreman_private_key_name) or (title == $ssl_foreman_cert_name) or (title == $ssl_crl_location_name) |> {
      ensure  => 'file',
      owner   => 'foreman',
      group   => 'puppet',
      mode    => '640',
      require => File[$foreman_cert_dir],
     }  
    file { $ssl_foreman_private_key_name:
      path    => "${foreman_cert_dir}/${ssl_foreman_private_key_name}",
      content => $ssl_foreman_private_key,
    } 
    file { $ssl_foreman_cert_name:
      path    => "${foreman_cert_dir}/${ssl_foreman_cert_name}",
      content => $ssl_foreman_cert,
    } 
    file { $ssl_crl_location_name:
      path    => "${foreman_cert_dir}/${ssl_crl_location_name}",
      content => $ssl_crl_location,
    } 
  }

  $foreman_hash = deep_merge($common_foreman_hash,
    {
      '::foreman' => {
        server_ssl_key  => "${foreman_cert_dir}/${ssl_foreman_private_key_name}",
        server_ssl_cert => "${foreman_cert_dir}/${ssl_foreman_cert_name}",
        server_ssl_crl  => "${foreman_cert_dir}/${ssl_crl_location_name}",
      }
    }
  )

} else {
  $foreman_hash = $common_foreman_hash
}

create_resources('class',$foreman_hash)

########################################################################
class { '::foreman_proxy':
  custom_repo           => true,
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
  log_level             => 'DEBUG',
}

concat::fragment {'foreman_settings_ssl.yaml':
  target  => '/etc/foreman/settings.yaml',
  content => "\n:ssl_certificate: /var/lib/puppet/ssl/certs/generic.${::domain}.pem\n:ssl_priv_key: /var/lib/puppet/ssl/private_keys/generic.${::domain}.pem",
  order   => '10',
}
