class bamboo::server (

  $version              = '4.2.0',
  $atlassian_vendor_dir = '/opt/atlassian',
  $user                 = 'bamboo-server',
  $group                = 'undefined',
  $home                 = 'undefined',
  $log_dir              = '/var/log',
  $run_dir              = '/var/run'

) {

  $bamboo_group = $group ? { 'undefined' => $user, default =>  $group }
  $bamboo_home  = $home ? { 'undefined' => "/var/lib/${user}", default => $home }
  $bamboo_tgz   = "atlassian-bamboo-${version}.tar.gz"
  $download_url = "http://www.atlassian.com/software/bamboo/downloads/binary/${bamboo_tgz}"

  if ! defined( File[ $atlassian_vendor_dir ] ) {
    file { $atlassian_vendor_dir: ensure => directory }
  }

  exec { 'download-bamboo-server':
    command => "wget ${download_url}",
    cwd     => $atlassian_vendor_dir,
    path    => [ '/bin', '/usr/bin', '/usr/local/bin' ],
    creates => "${atlassian_vendor_dir}/${bamboo_tgz}",
    require => File[ $atlassian_vendor_dir ],
  }

  exec { 'extract-bamboo-server':
    command => "tar -xf ${bamboo_tgz}",
    cwd     => $atlassian_vendor_dir,
    path    => [ '/bin', '/usr/bin', '/usr/local/bin' ],
    require => Exec[ 'download-bamboo-server' ],
    creates => "${atlassian_vendor_dir}/Bamboo",
  }

  group { $bamboo_group: ensure => present }

  user { $user:
    gid     => $bamboo_group,
    home    => $bamboo_home,
    require => Group[ $bamboo_group ],
  }

  file { $bamboo_home:
    ensure  => directory,
    owner   => $user,
    require => User[ $user ],
  }

  file_line { 'set-bamboo-home-in-bamboo-init.properties':
    path    => "${bamboo_home}/webapp/WEB-INF/classes/bamboo-init.properties",
    line    => "bamboo.home=${bamboo_home}",
    match   => '^#?bamboo.home=.*$',
    require => Exec[ 'extract-bamboo-server' ],
  }

  file { "/etc/init.d/${user}":
    ensure => link,
    target => "${atlassian_vendor_dir}/Bamboo",
    require => Exec[ 'extract-bamboo-server' ],
  }

  if ! defined( File[ '/etc/default' ] ) {
    file { '/etc/default': ensure => directory }
  }

  file { '/etc/default/bamboo':
    ensure  => present,
    source  => template( 'bamboo/defaults.erb' ),
    require => [ File[ '/etc/default' ], File[ 'symlink-init-script' ] ],
  }

  service { 'bamboo-server':
    ensure  => running,
    enabled => true,
    require => File[ '/etc/default/bamboo' ],
  }
}
