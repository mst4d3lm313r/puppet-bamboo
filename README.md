## Install ##

On a modern ( >= 2.7.14 ) Puppet

````bash

  puppet module install justinstoller/bamboo

````

## Usage ##

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
