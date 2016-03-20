#
$tstr = "apache::purge_configs: false\napache::purge_vhost_dir: false"
file {'/etc/hiera/plugins/fuel-plugin-lcm.yaml':
  ensure => present,
  content => $tstr,
}

