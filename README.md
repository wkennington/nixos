# William's NixOS Config System

TODO

## ZFS on Root Configuration
The expected configuration of the root zpool for the system is as follows.

```
$ zfs list
NAME                    USED  AVAIL  REFER  MOUNTPOINT
root                   2.61G  88.4G  3.62M  legacy
root/conf              2.85M  88.4G  2.85M  legacy
root/log                148M  88.4G   148M  legacy
root/nix               1.79G  88.4G  1.79G  legacy
root/state              675M  88.4G   675M  legacy
root/state/postgresql   272K  88.4G   272K  legacy
root/tmp               1.20M  88.4G  1.20M  legacy
```

```
$ zfs get all | grep local
root                   mountpoint            legacy                 local
root                   compression           lz4                    local
root                   atime                 off                    local
root                   xattr                 sa                     local
root/conf              devices               off                    local
root/conf              setuid                off                    local
root/log               devices               off                    local
root/log               setuid                off                    local
root/state             devices               off                    local
root/state             setuid                off                    local
root/state/postgresql  recordsize            8K                     local
root/state/postgresql  primarycache          metadata               local
root/state/postgresql  secondarycache        metadata               local
root/state/postgresql  logbias               throughput             local
root/tmp               devices               off                    local
root/tmp               setuid                off                    local
root/tmp               sync                  disabled               local
```

## ZFS on Ceph OSDs
The expected configuration of the pool servicing a ceph osd.

```
$ zfs get all osdN | grep local
osdN        mountpoint            legacy                 local
osdN        compression           lz4                    local
osdN        atime                 off                    local
osdN        devices               off                    local
osdN        exec                  off                    local
osdN        setuid                off                    local
osdN        xattr                 sa                     local
```
