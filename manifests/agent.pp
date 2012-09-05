#
# Usage:
# class { 'bamboo::client':
#   server      => 'builder-master.acctest.dc1.puppetlabs.net',
#                                    # ^^ fqdn of bamboo master, no default
#   server_port => '8085'            # port of bamboo master, default shown
#   version     => '4.2.0',          # the version is needed, default shown
#   agent_home  => '/var/lib/bamboo' # make sure all parent directories exist, default shown
#   user        => 'bamboo-agent'    # user to run agent as, default shown
#   group       => 'bamboo-agent'    # group to install as, default shown
#   ignore_cert => true              # should the agent ignore self signed certs?
# }
class bamboo::agent (

  $server_port = '8085',
  $version     = '4.2.0',
  $user        = 'bamboo-agent',
  $group       = 'bamboo-agent',
  $home        = "undefined",
  $ignore_cert = true,
  $server

) {

  $cert_val = $ignore_cert ? {
    true,'true','TRUE':     'TRUE',
    false,'false','FALSE':  'FALSE'
  }
  $initscript = "/etc/init.d/${user}"
  $agent_jar  = "atlassian-bamboo-agent-installer-${version}.jar"
  $agent_home = $home ? {
    'undefined' => "/var/lib/${user}",
     default    => $home
  }

  group { $group:
    ensure => present,
  }

  user { $user:
    home    => $agent_home,
    ensure  => present,
    gid     => $group,
    require => Group[$group],
  }

  file { $agent_home:
    ensure  => directory,
    owner   => $user,
    require => User[$user],
  }

  exec { 'download-bamboo-agent-jar':
    command  => "wget http://${server}:${server_port}/agentServer/agentInstaller/${agent_jar}",
    cwd      => $agent_home,
    path     => ['/usr/bin', '/bin'],
    creates  => "${agent_home}/${agent_jar}",
    require  => File[$agent_home],
  }

  file { "${agent_home}/${agent_jar}":
    ensure  => present,
    owner   => $user,
    require => Exec['download-bamboo-agent-jar'],
  }

  exec { 'install-bamboo-agent':
    command => "java -jar -Dbamboo.home=${agent_home} ${agent_jar} http://${server}:${server_port} install",
    cwd     => $agent_home,
    path    => [ '/bin', '/usr/bin', '/usr/local/bin' ],
    creates => "${agent_home}/bin",
    require => File[ "${agent_home}/${agent_jar}" ],
  }

  if ! defined(File['/var/lock/subsys']) {
    file { '/var/lock/subsys': ensure => directory, owner => root }
  }

  file { "/var/lock/subsys/${user}":
    ensure => directory,
    owner  => $user,
  }

  file { "/var/run/${user}":
    ensure => directory,
    owner  => $user,
  }

  File_line { path => "${agent_home}/bin/bamboo-agent.sh",
    require => Exec['install-bamboo-agent'],
    before  => Concat[ $initscript ],
  }

  file_line { 'bamboo-initscript-wrapper-cmd':
    line  => "WRAPPER_CMD='${agent_home}/bin/wrapper'",
    match => '^WRAPPER_CMD=',
  }

  file_line { 'bamboo-initscript-wrapper-conf':
    line  => "WRAPPER_CONF='${agent_home}/conf/wrapper.conf'",
    match => '^WRAPPER_CONF=',
  }

  file_line { 'bamboo-initscript-lockdir':
    line  => "LOCKDIR='/var/lock/subsys/${user}'",
    match => '^LOCKDIR=',
  }

  file_line { 'bamboo-initscript-piddir':
    line  => "PIDDIR='/var/run/${user}'",
    match => '^PIDDIR=',
  }

  file_line { 'bamboo-initscript-run-user':
    line  => "RUN_AS_USER='${user}'",
    match => '^\S*RUN_AS_USER=',
  }

  concat { $initscript: }

  concat::fragment { 'bamboo-lsb-header':
    target  => $initscript,
    content => template( 'bamboo/lsb_header.erb' ),
    order   => '01',
  }

  concat::fragment{ 'bamboo-initscript-body':
    target  => $initscript,
    ensure  => "${agent_home}/bin/bamboo-agent.sh",
    order   => '02',
    require => Exec[ 'install-bamboo-agent' ],
  }

  service { 'bamboo-agent':
    ensure  => 'running',
    enable  => true,
    require => Concat[ $initscript ],
  }

  file_line { 'bamboo-conf-classpath-1':
    path    => "${agent_home}/conf/wrapper.conf",
    line    => "wrapper.java.classpath.1=${agent_home}/lib/wrapper.jar",
    match   => '^wrapper.java.classpath.1=',
    require => Exec[ 'install-bamboo-agent' ],
  }

  file_line { 'bamboo-conf-classpath-2':
    path    => "${agent_home}/conf/wrapper.conf",
    line    => "wrapper.java.classpath.2=${agent_home}/lib/bamboo-agent-bootstrap.jar",
    match   => '^wrapper.java.classpath.2=',
    require => Exec[ 'install-bamboo-agent' ],
  }

  file_line { 'bamboo-conf-librarypath-1':
    path    => "${agent_home}/conf/wrapper.conf",
    line    => "wrapper.java.library.path.1=${agent_home}/lib",
    match   => '^wrapper.java.library.path.1=',
    require => Exec[ 'install-bamboo-agent' ],
  }

  file_line { 'bamboo-conf-ignore-cert':
    path    => "${agent_home}/conf/wrapper.conf",
    line    => "wrapper.java.additional.2=-Dbamboo.agent.ignoreServerCertName=${cert_val}",
    match   => '^wrapper.java.additional.2=-Dbamboo.agent.ignoreServerCertName=',
    require => Exec[ 'install-bamboo-agent' ],
  }
}
