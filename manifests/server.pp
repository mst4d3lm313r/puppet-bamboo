class bamboo::server (

  $version              = '4.2.0',
  $atlassian_vendor_dir = '/opt/atlassian',
  $user                 = 'bamboo-server',
  $group                = 'undefined',
  $home                 = 'undefined'

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
}
