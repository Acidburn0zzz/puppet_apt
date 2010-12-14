class apt::preferences {

  include common::moduledir
  $apt_preferences_dir = "${common::moduledir::module_dir_path}/apt/preferences"
  module_dir{'apt/preferences': }
  file { "${apt_preferences_dir}_header":
    content => $custom_preferences ? {
      '' => $operatingsystem ? {
        'debian' => template("apt/${operatingsystem}/preferences_${codename}.erb"),
        'ubuntu' => '',
      },
      default => $custom_preferences
    },
  }

  concatenated_file { '/etc/apt/preferences':
    dir => $apt_preferences_dir,
    header => "${apt_preferences_dir}_header",
    # use Concatenated_file[apt_config] to reference a completed configuration
    # See "The Puppet Semaphor" 2007-06-25 on the puppet-users ML
    alias => apt_config,
    # only update together
    require => File["/etc/apt/sources.list"];
  }

}