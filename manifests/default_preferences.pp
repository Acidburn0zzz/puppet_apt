class apt::default_preferences {
  config_file {
    # this just pins unstable and testing to very low values
    "/etc/apt/preferences":
      content => template("apt/preferences_${codename}.erb"),
      # use File[apt_config] to reference a completed configuration
      # See "The Puppet Semaphor" 2007-06-25 on the puppet-users ML
      alias => apt_config,
      # only update together
      require => File["/etc/apt/sources.list"];
    # little default settings which keep the system sane
    "/etc/apt/apt.conf.d/from_puppet":
      content => "APT::Get::Show-Upgraded true;\nDSelect::Clean $real_apt_clean;\n",
      before => Config_file[apt_config];
  }
}
