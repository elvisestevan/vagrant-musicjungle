exec { "apt-update":
  command => "/usr/bin/apt-get update"
}

package { ["openjdk-7-jre", "tomcat7", "mysql-server"]:
  ensure => installed,
  require => Exec["apt-update"]
}

service { "tomcat7":
  ensure => running,
  enable => true,
  hasstatus => true,
  hasrestart => true,
  require => Package["tomcat7"]
}

exec { "get_vraptor-musicjungle":
  command => "/usr/bin/wget -q http://central.maven.org/maven2/br/com/caelum/vraptor-musicjungle/4.0.0-beta-1/vraptor-musicjungle-4.0.0-beta-1.war -O /home/vagrant/vraptor-musicjungle.war",
  creates => "/home/vagrant/vraptor-musicjungle.war"
}

file { "/home/vagrant/vraptor-musicjungle.war":
  require => Exec["get_vraptor-musicjungle"]
}

file { "/var/lib/tomcat7/webapps/vraptor-musicjungle.war":
  source => "/home/vagrant/vraptor-musicjungle.war",
  owner => tomcat7,
  group => tomcat7,
  mode => 0644,
  require => Package["tomcat7"],
  notify => Service["tomcat7"]
}

service { "mysql":
  ensure => running,
  enable => true,
  hasstatus => true,
  hasrestart => true,
  require => Package["mysql-server"]
}

exec { "create_database_musicjungle":
  command => "mysqladmin -uroot create musicjungle",
  unless => "mysql -uroot musicjungle",
  path => "/usr/bin",
  require => Service["mysql"]
}

exec { "create_user_mysql_musicjungle":
  command => "mysql -uroot -e \"GRANT ALL PRIVILEGES ON * TO 'musicjungle'@'%' IDENTIFIED BY 'minha-senha';\" musicjungle",
  unless => "mysql -umusicjungle -pminha-senha musicjungle",
  path => "/usr/bin",
  require => Exec["create_database_musicjungle"]
}

file_line { "production":
  file => "/etc/default/tomcat7",
  line => "JAVA_OPTS=\"\$JAVA_OPTS -Dbr.com.caelum.vraptor.environment=production\"",
  require => Package["tomcat7"],
  notify => Service["tomcat7"]
}

define file_line($file, $line) {
  exec { "/bin/echo '${line}' >> '${file}'":
    unless => "/bin/grep -qFx '${line}' '${file}'"
  }
}
