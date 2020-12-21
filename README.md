# puppet-glusterfs

## Overview

Install, enable and configure GlusterFS.

* `glusterfs::server` : Class to install and enable the server.
* `glusterfs::peer` : Definition to add a server peer. Used by the server class' $peer parameter.
* `glusterfs::volume` : Definition to create server volumes.
* `glusterfs::client` : Class to install and enable the client. Included from the mount definition.
* `glusterfs::mount` : Definition to create client mounts.

You will need to open TCP ports 24007:24009 and 38465:38466 on the servers.

## Examples

Complete server with two redundant nodes, on top of existing kickstart created vg0 LVM VGs.
Note that the first runs will fail since the volume creation won't work until
the peers know each other, and that requires the service to be running:

```puppet
  $mypeer = $facts['hostname'] ? {
    'server1' => '192.168.0.2',
    'server2' => '192.168.0.1',
  }
  file { [ '/export', '/export/gv0' ]:
    ensure  => directory,
    seltype => 'usr_t',
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
  class { 'glusterfs::server':
    peers => $facts['hostname'] ? {
      'server1' => '192.168.0.2',
      'server2' => '192.168.0.1',
    },
  }
  glusterfs::volume { 'gv0':
    create_options => 'replica 2 192.168.0.1:/export/gv0 192.168.0.2:/export/gv0',
    require        => Mount['/export/gv0'],
  }
```

Client mount (the client class is included automatically). Note that clients
are virtual machines on the servers above, so make each of them use the replica
on the same hardware for optimal performance and optimal fail-over :

```puppet
  file { '/var/www': ensure => directory }
  glusterfs::mount { '/var/www':
    device => $facts['hostname'] ? {
      'client1' => '192.168.0.1:/gv0',
      'client2' => '192.168.0.2:/gv0',
    }
  }
```

## Note

This is a fork of `thias-glusterfs`.
It's merely the same, apart from:

* `yes` command prepended to volume creation, to skip the user interaction to confirm the operation.
* minor fixes against puppet-lint
