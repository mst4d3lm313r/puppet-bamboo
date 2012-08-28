## Install ##

On a modern ( >= 2.7.14 ) Puppet

````bash

  puppet module install justinstoller/bamboo

````

## Usage ##

To install a basic Bamboo Server:

````puppet

#
# This requires no parameters for a basic embedded db
#
class { 'bamboo::server':
  version              => '4.2.0',            # default shown
  atlassian_vendor_dir => '/opt/atlassian',   # where to vendor atlassian products, default shown

  user                 => 'bamboo-server',    # should be a valid file path
  group                => $user,              # default shown
  home                 => "/var/lib/$user",   # where config files are stored, default shown

  log_dir              => "/var/log/${user}/bamboo.log", # default shown
  run_dir              => "/var/run/${user}/bamboo.pid"  # default shown
}

````

To install a Bamboo Remote Agent:

````puppet

class { 'bamboo::client':
  server      => 'builder-master.acctest.dc1.puppetlabs.net',
                                    # ^^ fqdn of bamboo master, no default

  server_port => '8085',            # port of bamboo master, default shown
  version     => 'bamboo-agent',    # group to install as, default shown
  agent_home  => '/var/lib/bamboo', # make sure all parent directories exist, default shown
  user        => 'bamboo-agent',    # user to run agent as, default shown
  group       => 'bamboo-agent'     # group to install as, default shown
}

````


Example site.pp using inkling/postgresql:

````puppet
$bamboo_master_hostname = 'bamboo-master.dc1.puppetlabs.net'

node $bamboo_master_hostname {

  class { 'bamboo::server': }

  class { 'postgresql::server': }

  postgresql::database { 'bamboo-server': }

  postgresql::database_user { 'bamboo-server':
    password_hash => postgresql_password('bamboo-server', 'password'),
  }

  postgresql::database_grant { 'grant bamboo-server all privileges on bamboo-server db':
    role => 'bamboo-server',
    db => 'bamboo-server',
    privilege => 'create',
    require => [ Postgresql::Database_user[ 'bamboo-server' ],
                   Postgresql::Database[ 'bamboo-server' ] ],
  }
}

node /bamboo-remote-agent-/ {
  class { 'bamboo::agent':
    server => $bamboo_master_hostname,
  }
}

````
