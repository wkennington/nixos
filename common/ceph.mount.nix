{ config, lib, ... }:
with lib;
let
  calculated = (import ./sub/calculated.nix { inherit config lib; });
in
{
  imports = [
    ./ceph.nix
  ];
  systemd.automounts = [ {
    wantedBy = [ "remote-fs.target" ];
    where = "/ceph";
  } ];
  systemd.mounts = [ {
    wants = [ "network-online.target" ];
    wantedBy = [ "remote-fs.target" ];
    after = [ "network.target" "network-interfaces.target" "network-online.target" "ceph-mds.service" "ceph-mon.service" ];
    type = "ceph";
    what = "${concatStringsSep "," calculated.myCeph.monIps}:/";
    where = "/ceph";
    options = [
      "name=admin"
      secretfile=/etc/ceph/ceph.client.admin.key"
    ];
    /*options = [
      "name=admin"
      "secretfile=/etc/ceph/ceph.client.admin.key"
      "fsc"
      "dcache"
    ];*/
  } ];
}
