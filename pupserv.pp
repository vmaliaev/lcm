class { '::puppet':
  agent => true,
  server => true,
  server_ca => true,
  server_foreman => false,
  server_reports => 'store',
  server_environments => [],
  server_external_nodes => '/etc/puppet/node.rb',
}
