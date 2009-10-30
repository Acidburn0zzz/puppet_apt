# apt.pp - common components and defaults for handling apt
# Copyright (C) 2008 Micah Anerson <micah@riseup.net>
# Copyright (C) 2007 David Schmitt <david@schmitt.edv-bus.at>
# See LICENSE for the full license granted to you.

class apt {

  # See README
  $real_apt_clean = $apt_clean ? {
    '' => 'auto',
    default => $apt_clean,
  }

  package { apt: ensure => installed }

  # a few templates need lsbdistcodename
  include assert_lsbdistcodename

  case $custom_sources_list {
    '': {
      include apt::default_sources_list
    }
    default: {
      config_file { "/etc/apt/sources.list":
        content => $custom_sources_list,
        require => Exec[assert_lsbdistcodename];
      }
    }
  }

  case $custom_preferences {
    '': {
      include apt::default_preferences
    }
    default: {
      config_file { "/etc/apt/preferences":
        content => $custom_preferences,
        alias => apt_config,
        require => File["/etc/apt/sources.list"];
      }
    }
  }

  $apt_base_dir = "${module_dir_path}/apt"
  module_dir { apt: }
  # watch apt.conf.d
  file { "/etc/apt/apt.conf.d": ensure => directory, checksum => mtime; }

  exec {
    # "&& sleep 1" is workaround for older(?) clients
    "/usr/bin/apt-get update && sleep 1 #on refresh":
      refreshonly => true,
      subscribe => [ File["/etc/apt/sources.list"],
                     File["/etc/apt/preferences"], 
                     File["/etc/apt/apt.conf.d"],
                     File[apt_config] ];
      "/usr/bin/apt-get update && /usr/bin/apt-get autoclean #hourly":
        require => [ File["/etc/apt/sources.list"],
                     File["/etc/apt/preferences"], File[apt_config] ],
        # Another Semaphor for all packages to reference
        alias => apt_updated;
  }

  ## This package should really always be current
  package { "debian-archive-keyring": ensure => latest }
        
  case $lsbdistcodename {
    etch: {
      package { "debian-backports-keyring": ensure => latest }
                
      # This key was downloaded from
      # http://backports.org/debian/archive.key
      # and is needed to bootstrap the backports trustpath
      file { "${apt_base_dir}/backports.org.key":
        source => "puppet://$servername/apt/backports.org.key",
        mode => 0444, owner => root, group => root,
      }
      exec { "/usr/bin/apt-key add ${apt_base_dir}/backports.org.key && apt-get update":
        alias => "backports_key",
        refreshonly => true,
        subscribe => File["${apt_base_dir}/backports.org.key"],
        before => [ File[apt_config], Package["debian-backports-keyring"] ]
      }
    }
    lenny: {
      package { "debian-backports-keyring": ensure => latest }

      # This key was downloaded from
      # http://backports.org/debian/archive.key
      # and is needed to bootstrap the backports trustpath
      file { "${apt_base_dir}/backports.org.key":
        source => "puppet://$servername/apt/backports.org.key",
        mode => 0444, owner => root, group => root,
      }
      exec { "/usr/bin/apt-key add ${apt_base_dir}/backports.org.key && apt-get update":
        alias => "backports_key",
        refreshonly => true,
        subscribe => File["${apt_base_dir}/backports.org.key"],
        before => [ File[apt_config], Package["debian-backports-keyring"] ]
      }
    }
  }

  case $custom_key_dir {
    '': {
      exec { "/bin/true # no_custom_keydir": }
    }
    default: {
      file { "${apt_base_dir}/keys.d":
        source => "$custom_key_dir",
        recurse => true,
        mode => 0755, owner => root, group => root,
      }
      exec { "find ${apt_base_dir}/keys.d -type f -exec apt-key add '{}' \\; && apt-get update":
        alias => "custom_keys",
        subscribe => File["${apt_base_dir}/keys.d"],
        refreshonly => true,
        before => File[apt_config];
      }
    }
  }

  # workaround for preseeded_package component
  file { "/var/cache": ensure => directory }
  file { "/var/cache/local": ensure => directory }
  file { "/var/cache/local/preseeding/": ensure => directory }
}     
