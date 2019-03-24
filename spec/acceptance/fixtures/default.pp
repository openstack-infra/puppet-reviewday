include pip

include reviewday

include httpd

file { '/srv/static':
  ensure => directory,
}

file { '/srv/static/status':
  ensure  => directory,
  require => File['/srv/static'],
}

$status_vhost = 'NameVirtualHost *:80
<VirtualHost *:80>
  ServerName localhost
  DocumentRoot /srv/static/status
  Alias /reviews /srv/static/reviewday
  <Directory /srv/static/reviewday>
      AllowOverride None
      Order allow,deny
      allow from all
      <IfVersion >= 2.4>
        Require all granted
      </IfVersion>
  </Directory>
  ErrorLog /var/log/apache2/status.openstack.org_error.log
  LogLevel warn
  CustomLog /var/log/apache2/status.openstack.org_access.log combined
  ServerSignature Off
</VirtualHost>'
::httpd::vhost { 'status.openstack.org':
  port     => 80,
  priority => '50',
  docroot  => '/srv/static/status',
  content  => $status_vhost,
  require  => File['/srv/static/status'],
}

reviewday::site { 'reviewday':
  git_url                       => 'https://git.openstack.org/openstack-infra/reviewday',
  serveradmin                   => 'webmaster@openstack.org',
  httproot                      => '/srv/static/reviewday',
  gerrit_url                    => 'review.openstack.org',
  gerrit_port                   => '29418',
  gerrit_user                   => 'reviewday',
  reviewday_gerrit_ssh_key      => '',
  reviewday_rsa_pubkey_contents => '',
  reviewday_rsa_key_contents    => '',
}
