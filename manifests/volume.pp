# Define: glusterfs::volume
#
# Simple way to create (not modify) and start GlusterFS volumes.
#
# Example Usage:
#  glusterfs::volume { 'gv0':
#    create_options => 'replica 2 192.168.0.1:/export/gv0 192.168.0.2:/export/gv0',
#  }
#
define glusterfs::volume (
  $create_options
) {

  exec {
    default:
      path => ['/usr/sbin', '/usr/bin', '/sbin', '/bin'];
    "gluster volume create ${title}":
      command => "yes | gluster volume create ${title} ${create_options}",
      creates => "/var/lib/glusterd/vols/${title}",
      require => Class['glusterfs::server'];
    "/usr/sbin/gluster volume start ${title}":
      unless  => "[ \"`gluster volume info ${title} | egrep '^Status:'`\" = 'Status: Started' ]",
      require => Exec["gluster volume create ${title}"];
  }

}
