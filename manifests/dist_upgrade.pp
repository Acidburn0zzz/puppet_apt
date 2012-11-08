class apt::dist_upgrade {

  if $apt::disable_update = false { include apt::update }

  exec { 'apt_dist-upgrade':
    command     => "/usr/bin/apt-get -q -y -o 'DPkg::Options::=--force-confold' dist-upgrade",
    refreshonly => true,
    require     => Exec['apt_updated'],
  }

}
