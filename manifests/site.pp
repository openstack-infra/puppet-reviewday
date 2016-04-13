# Copyright 2013 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# == Define: reviewday
#
define reviewday::site(
  $gerrit_url = 'localhost',
  $gerrit_port = '29418',
  $gerrit_user = 'reviewday',
  $reviewday_rsa_key_contents = undef,
  $reviewday_rsa_pubkey_contents = undef,
  $reviewday_gerrit_ssh_key = undef,
  $git_url = 'git://git.openstack.org/openstack-infra/reviewday',
  $httproot = '/srv/static/reviewday',
  $serveradmin = 'webmaster@example.org'
) {

  file { '/var/lib/reviewday/.ssh/':
    ensure  => directory,
    owner   => 'reviewday',
    group   => 'reviewday',
    mode    => '0700',
    require => User['reviewday'],
  }

  if $reviewday_rsa_key_contents != undef {
    file { '/var/lib/reviewday/.ssh/id_rsa':
      owner   => 'reviewday',
      group   => 'reviewday',
      mode    => '0600',
      content => $reviewday_rsa_key_contents,
      replace => true,
      require => File['/var/lib/reviewday/.ssh/']
    }
  }

  if $reviewday_rsa_pubkey_contents != undef {
    file { '/var/lib/reviewday/.ssh/id_rsa.pub':
      owner   => 'reviewday',
      group   => 'reviewday',
      mode    => '0600',
      content => $reviewday_rsa_pubkey_contents,
      replace => true,
      require => File['/var/lib/reviewday/.ssh/']
    }
  }

  if $reviewday_gerrit_ssh_key != undef {
    file { '/var/lib/reviewday/.ssh/known_hosts':
      owner   => 'reviewday',
      group   => 'reviewday',
      mode    => '0600',
      content => "${gerrit_url} ${reviewday_gerrit_ssh_key}",
      replace => true,
      require => File['/var/lib/reviewday/.ssh/']
    }
  }

  file {'/var/lib/reviewday/reviewday':
    ensure  => directory,
    owner   => 'reviewday',
    group   => 'reviewday',
    mode    => '0755',
    require => File['/var/lib/reviewday/'],
  }

  vcsrepo { '/var/lib/reviewday/reviewday':
    ensure   => latest,
    provider => git,
    source   => $git_url,
    revision => 'master',
  }

  exec { 'install-reviewday-dependencies':
    command   => 'pip install -r requirements.txt',
    path      => '/usr/local/bin/:/bin/:/var/lib/reviewday/reviewday',
    subscribe => Vcsrepo['/var/lib/reviewday/reviewday'],
    require   => Class['pip'],
  }

  file { $httproot:
    ensure => directory,
    owner  => 'reviewday',
    group  => 'reviewday',
    mode   => '0755',
  }

  file { '/var/lib/reviewday/.ssh/config':
    ensure  => present,
    content => template('reviewday/ssh_config.erb'),
    owner   => 'reviewday',
    group   => 'reviewday',
    mode    => '0644',
  }

  cron { 'update reviewday':
    command => "cd /var/lib/reviewday/reviewday && PYTHONPATH=\$PWD flock -n /var/lib/reviewday/update.lock python bin/reviewday -o ${httproot}",
    minute  => '*/30',
    user    => 'reviewday',
    require => Exec['install-reviewday-dependencies'],
  }

}

# vim:sw=2:ts=2:expandtab:textwidth=79
