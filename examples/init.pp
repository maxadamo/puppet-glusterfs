# The baseline for module testing used by Puppet Inc. is that each manifest
# should have a corresponding test manifest that declares that class or defined
# type.
#
# Tests are then run by using puppet apply --noop (to check for compilation
# errors and view a log of events) or by fully applying the test in a virtual
# environment (to compare the resulting system state to the desired state).
#
# Learn more about module testing here:
# https://docs.puppet.com/guides/tests_smoke.html
#
$mypeer = $::hostname ? {
  'server1' => '192.168.0.2',
  'server2' => '192.168.0.1',
}

file { [ '/export', '/export/gv0' ]:
  ensure  => directory,
  seltype => 'usr_t';
}

logical_volume { 'lv_glusterfs':
  ensure       => present,
  volume_group => 'rootvg',
  size         => '4G';
}

filesystem { '/dev/mapper/rootvg-lv_glusterfs':
  ensure  => present,
  fs_type => 'ext4',
  require => Logical_volume['lv_glusterfs'];
}

mount { '/export/gv0':
  ensure  => mounted,
  device  => '/dev/mapper/rootvg-lv_glusterfs',
  fstype  => 'ext4',
  options => 'defaults',
  require => [
    Filesystem['/dev/mapper/rootvg-lv_glusterfs'],
    File['/export/gv0']
  ];
}

class { 'glusterfs::server': peers => $mypeer; }

glusterfs::volume { 'gv0':
  create_options => 'replica 2 192.168.0.1:/export/gv0 192.168.0.2:/export/gv0',
  require        => Mount['/export/gv0'],
}
