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
  $version              => '4.2.0',            # default shown
  $atlassian_vendor_dir => '/opt/atlassian',   # where to vendor atlassian products, default shown

  $user                 => 'bamboo-server',    # should be a valid file path
  $group                => $user,              # default shown
  $home                 => "/var/lib/$user",   # where config files are stored, default shown

  $log_dir              => "/var/log/${user}/bamboo.log", # default shown
  $run_dir              => "/var/run/${user}/bamboo.pid"  # default shown
}

````

To install a Bamboo Remote Agent:

````puppet

class { 'bamboo::client':
  server      => 'builder-master.acctest.dc1.puppetlabs.net',
                                   # ^^ fqdn of bamboo master, no default

  server_port => '8085'            # port of bamboo master, default shown
  version     => 'bamboo-agent'    # group to install as, default shown
  agent_home  => '/var/lib/bamboo' # make sure all parent directories exist, default shown
  user        => 'bamboo-agent'    # user to run agent as, default shown
  group       => 'bamboo-agent'    # group to install as, default shown
}

````
