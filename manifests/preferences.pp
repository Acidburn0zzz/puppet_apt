class apt::preferences {

  concat::fragment{"apt_preferences_header":
    content => $apt::custom_preferences ? {
      '' => $::operatingsystem ? {
        'debian' => template("apt/${::operatingsystem}/preferences_${::lsbdistcodename}.erb"),
        'ubuntu' => template("apt/${::operatingsystem}/preferences_${::lsbdistcodename}.erb"),
      },
      default => $custom_preferences
    },
    order => 00,
    target => '/etc/apt/preferences',
  }

  concat{'/etc/apt/preferences':
    alias => apt_config,
    # only update together
    require => File["/etc/apt/sources.list"],
    owner => root, group => 0, mode => 0644;
  }

}
