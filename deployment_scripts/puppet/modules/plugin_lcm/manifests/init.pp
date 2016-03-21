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

class plugin_lcm {

  # Hiera lookups
  $lcm_network_metadata     = hiera('network_metadata')
  $lcm_network_scheme       = hiera('network_scheme')
  $lcm_my_uid               = hiera('uid')
  $lcm_my_name              = hiera('node_name')
  $lcm_hiera_values         = hiera('fuel-plugin-lcm', {})
  $neutron_config           = hiera_hash('neutron_config')
  $mgmt_cidr                = hiera('management_network_range')
  $fuel_access              = hiera('access')
  $cluster_id               = hiera('deployment_id')
  $master_ip                = hiera('master_ip')

  # Copy paste from: modules/osnailyfacter/modular/openstack-network/networks.pp
  $floating_net             = try_get_value($neutron_config, 'default_floating_net', 'net04_ext')
  $nets                     = $neutron_config['predefined_networks']
  $public_cidr              = try_get_value($nets, "${floating_net}/L3/subnet")

  # Plugin defaults
  $lcm_namespace_name       = 'haproxy'
  $lcm_namespace_cidr_mask  = '10.255'
  $lcm_ka_auth_type         = 'PASS'
  $lcm_ka_garp_master_delay = '3'
  $lcm_ka_master_priority   = '200'
  $lcm_ka_instance_name     = 'LCM'

  # Plugin specific options
  $lcm_hapub_enabled        = pick($lcm_hiera_values['public_vip_enabled'], false)
  $lcm_pub_veth_name        = regsubst($lcm_namespace_name,'^(..).*','\1pub')
  $lcm_mgmt_veth_name       = regsubst($lcm_namespace_name,'^(..).*','\1mgmt')
  $lcm_virtual_router_id    = pick($lcm_hiera_values['keepalived_vrid'], '50')
  $lcm_ka_auth_pass         = pick($lcm_hiera_values['metadata']['keepalived_psk'],'lcmKA50s')
  $lcm_my_mgmt_ip           = $lcm_network_metadata['nodes'][$lcm_my_name]['network_roles']['lcm_mgmt']
  $lcm_nodes_hash           = get_nodes_hash_by_roles($lcm_network_metadata, ['lcm'])
  $lcm_primary_hash         = get_nodes_hash_by_roles($lcm_network_metadata, ['primary-lcm'])
  $lcm_all_hash             = get_nodes_hash_by_roles($lcm_network_metadata, ['lcm','primary-lcm'])
  $lcm_nodes_ips            = values(get_node_to_ipaddr_map_by_network_role($lcm_all_hash, 'lcm_mgmt'))
  $lcm_nodes_names          = keys(get_node_to_ipaddr_map_by_network_role($lcm_all_hash, 'lcm_mgmt'))
  $lcm_nodes_keys           = keys($lcm_nodes_hash)
  $lcm_primary_key          = keys($lcm_primary_hash)
  $lcm_primary_uid          = $lcm_primary_hash[$lcm_primary_key[0]]['uid']
  $lcm_vip                  = $lcm_network_metadata['vips']['lcm']['ipaddr']
  $lcm_public_vip           = $lcm_network_metadata['vips']['lcmpub']['ipaddr']
  $lcm_public_iface         = $lcm_network_scheme['roles']['lcm_pub']
  $lcm_public_gateway       = $lcm_network_scheme['endpoints'][$lcm_public_iface]['gateway']
  $lcm_mgmt_iface           = $lcm_network_scheme['roles']['lcm_mgmt']
  $lcm_apache_ports         = [ '80', '443', '8140', '9292' ]
}
