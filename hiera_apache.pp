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

notice('PLUGIN: fuel-plugin-lcm/hiera_apache.pp')

$tstr = "apache::purge_configs: false\napache::purge_vhost_dir: false"

file {'/etc/hiera/plugins/fuel-plugin-lcm.yaml':
  ensure  => present,
  content => $tstr,
}
