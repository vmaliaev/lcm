# Manage your foreman server
#
# === Parameters:
#
# All the parameters look at ::foreman::init.pp
#

class foreman_ext (
  $foreman_url               = $::foreman::params::foreman_url,
  $puppetrun                 = $::foreman::params::puppetrun,
  $unattended                = $::foreman::params::unattended,
  $authentication            = $::foreman::params::authentication,
  $passenger                 = $::foreman::params::passenger,
  $passenger_ruby            = $::foreman::params::passenger_ruby,
  $passenger_ruby_package    = $::foreman::params::passenger_ruby_package,
  $plugin_prefix             = $::foreman::params::plugin_prefix,
  $use_vhost                 = $::foreman::params::use_vhost,
  $servername                = $::foreman::params::servername,
  $serveraliases             = $::foreman::params::serveraliases,
  $ssl                       = $::foreman::params::ssl,
  $custom_repo               = $::foreman::params::custom_repo,
  $repo                      = $::foreman::params::repo,
  $configure_epel_repo       = $::foreman::params::configure_epel_repo,
  $configure_scl_repo        = $::foreman::params::configure_scl_repo,
  $configure_brightbox_repo  = $::foreman::params::configure_brightbox_repo,
  $selinux                   = $::foreman::params::selinux,
  $gpgcheck                  = $::foreman::params::gpgcheck,
  $version                   = $::foreman::params::version,
  $db_manage                 = $::foreman::params::db_manage,
  $db_type                   = $::foreman::params::db_type,
  $db_adapter                = 'UNSET',
  $db_host                   = 'UNSET',
  $db_port                   = 'UNSET',
  $db_database               = 'UNSET',
  $db_username               = $::foreman::params::db_username,
  $db_password               = $::foreman::params::db_password,
  $db_sslmode                = 'UNSET',
  $db_pool                   = $::foreman::params::db_pool,
  $apipie_task               = $::foreman::params::apipie_task,
  $app_root                  = $::foreman::params::app_root,
  $manage_user               = $::foreman::params::manage_user,
  $user                      = $::foreman::params::user,
  $group                     = $::foreman::params::group,
  $user_groups               = $::foreman::params::user_groups,
  $environment               = $::foreman::params::environment,
  $puppet_home               = $::foreman::params::puppet_home,
  $locations_enabled         = $::foreman::params::locations_enabled,
  $organizations_enabled     = $::foreman::params::organizations_enabled,
  $passenger_interface       = $::foreman::params::passenger_interface,
  $server_ssl_ca             = $::foreman::params::server_ssl_ca,
  $server_ssl_chain          = $::foreman::params::server_ssl_chain,
  $server_ssl_cert           = $::foreman::params::server_ssl_cert,
  $server_ssl_certs_dir      = $::foreman::params::server_ssl_certs_dir,
  $server_ssl_key            = $::foreman::params::server_ssl_key,
  $server_ssl_crl            = $::foreman::params::server_ssl_crl,
  $oauth_active              = $::foreman::params::oauth_active,
  $oauth_map_users           = $::foreman::params::oauth_map_users,
  $oauth_consumer_key        = $::foreman::params::oauth_consumer_key,
  $oauth_consumer_secret     = $::foreman::params::oauth_consumer_secret,
  $passenger_prestart        = $::foreman::params::passenger_prestart,
  $passenger_min_instances   = $::foreman::params::passenger_min_instances,
  $passenger_start_timeout   = $::foreman::params::passenger_start_timeout,
  $admin_username            = $::foreman::params::admin_username,
  $admin_password            = $::foreman::params::admin_password,
  $admin_first_name          = $::foreman::params::admin_first_name,
  $admin_last_name           = $::foreman::params::admin_last_name,
  $admin_email               = $::foreman::params::admin_email,
  $initial_organization      = $::foreman::params::initial_organization,
  $initial_location          = $::foreman::params::initial_location,
  $ipa_authentication        = $::foreman::params::ipa_authentication,
  $http_keytab               = $::foreman::params::http_keytab,
  $pam_service               = $::foreman::params::pam_service,
  $ipa_manage_sssd           = $::foreman::params::ipa_manage_sssd,
  $websockets_encrypt        = $::foreman::params::websockets_encrypt,
  $websockets_ssl_key        = $::foreman::params::websockets_ssl_key,
  $websockets_ssl_cert       = $::foreman::params::websockets_ssl_cert,
  $logging_level             = $::foreman::params::logging_level,
  $loggers                   = $::foreman::params::loggers,
  $email_conf                = $::foreman::params::email_conf,
  $email_source              = $::foreman::params::email_source,
  $email_delivery_method     = $::foreman::params::email_delivery_method,
  $email_smtp_address        = $::foreman::params::email_smtp_address,
  $email_smtp_port           = $::foreman::params::email_smtp_port,
  $email_smtp_domain         = $::foreman::params::email_smtp_domain,
  $email_smtp_authentication = $::foreman::params::email_smtp_authentication,
  $email_smtp_user_name      = $::foreman::params::email_smtp_user_name,
  $email_smtp_password       = $::foreman::params::email_smtp_password,
) inherits foreman::params {

  if $db_adapter == 'UNSET' {
    $db_adapter_real = $::foreman::db_type ? {
      'sqlite' => 'sqlite3',
      'mysql'  => 'mysql2',
      default  => $::foreman::db_type,
    }
  } else {
    $db_adapter_real = $db_adapter
  }
  validate_bool($passenger)
  if $passenger == false and $ipa_authentication {
    fail("${::hostname}: External authentication via IPA can only be enabled when passenger is used.")
  }
  validate_bool($websockets_encrypt)
  validate_re($logging_level, '^(debug|info|warn|error|fatal)$')
  validate_hash($loggers)
  validate_array($serveraliases)
  if $email_delivery_method {
    validate_re($email_delivery_method, ['^sendmail$', '^smtp$'], "email_delivery_method can be either sendmail or smtp, not ${email_delivery_method}")
  }
  validate_bool($puppetrun)

#  class { '::foreman::install': } ~>
#  class { '::foreman::config': } ~>
#  class { '::foreman::database': } #~>
#  class { '::foreman::service': } ->
#  Class['foreman'] ->
#  Foreman_smartproxy <| base_url == $foreman_url |>
##############################################################################################3
    validate_string($::foreman::admin_username, $::foreman::admin_password, $::foreman::apipie_task)
    validate_re($::foreman::apipie_task, '^apipie:')

    $db_class = "foreman::database::${::foreman::db_type}"
    $seed_env = {
      'SEED_ADMIN_USER'       => $::foreman::admin_username,
      'SEED_ADMIN_PASSWORD'   => $::foreman::admin_password,
      'SEED_ADMIN_FIRST_NAME' => $::foreman::admin_first_name,
      'SEED_ADMIN_LAST_NAME'  => $::foreman::admin_last_name,
      'SEED_ADMIN_EMAIL'      => $::foreman::admin_email,
      'SEED_ORGANIZATION'     => $::foreman::initial_organization,
      'SEED_LOCATION'         => $::foreman::initial_location,
    }

    if $::foreman::passenger {
      $foreman_service = Class['apache::service']
    } else {
      $foreman_service = Class['foreman::service']
    }

#    class { $db_class: } ~>
    Class['foreman::database'] ~>
    foreman_config_entry { 'db_pending_migration':
      value => false,
      dry   => true,
    } ~>
    foreman::rake { 'db:migrate': } ~>
    foreman_config_entry { 'db_pending_seed':
      value  => false,
      dry    => true,
      # to address #7353: settings initialization race condition
      before => $foreman_service,
    } ~>
    foreman::rake { 'db:seed':
      environment => delete_undef_values($seed_env),
    } ~>
    foreman::rake { $::foreman::apipie_task:
      timeout => 0,
    } ~>
    Class['foreman::service']

#    class { '::foreman::service': }
##############################################################################
  # Anchor these separately so as not to break
  # the notify between main classes
#  Class['foreman::install'] ~>
#  Package <| tag == 'foreman-compute' |> ~>
#  Class['foreman::service']

  # lint:ignore:spaceship_operator_without_tag
#  Class['foreman::database']~>
#  Foreman::Plugin <| |> ~>
#  Class['foreman::service']
  # lint:endignore

}
