{ lib, ... }:
let
  vars = (import ./vars.nix { inherit lib; });
in
with lib;
{
  dedicated = [
    "jester"
    "atomic"
    "alamo"
    "newton"
    "page"
    "quest"
  ];
  hosts = mkMerge [
    {
      jester = ''
        Address = jester.bhs.wak.io
        Ed25519PublicKey = Eh3ibLbSRdSdReJTVTzgdJj8nBLjEokdy+/1VaseaLN
      '';
      atomic = ''
        Address = atomic.abe-p.wak.io
        Ed25519PublicKey = wzPej5rz8cMNWE7YO2DIGUgChZ9CkfYkFIz1J0YCfKP
        Subnet = 10.0.0.0/16
      '';
      alamo = ''
        Address = alamo.mtv-w.wak.io
        Ed25519PublicKey = 6zMuqE3EAZvc/lZ2FpKoGweT3ihv6Cas4bwHcuU6TGG
        Subnet = 10.1.0.0/16
      '';
      ferrari = ''
        Address = ferrari.mtv-w.wak.io
        Ed25519PublicKey = HuyBA/Ol/wH6y4tj4XR6IDI5FLIAcfcdnGXU974K9pC
        Subnet = 10.1.0.0/16
      '';
      legend = ''
        Address = legend.mtv-w.wak.io
        Ed25519PublicKey = Yqo9IB/XzIA+1QumkTIasL8mFEdd+oc7L3TRLWkxHGH
      '';
      delta = ''
        Ed25519PublicKey = Amd0wHchaDaH25n+4/YEUpCvxDCxjD/vocevi1/wJWB
      '';
      prodigy = ''
        Ed25519PublicKey = kKcEmjbD+1Fx8llu6xlAQsBiuSmb2wJp8PzhAnGtezI
      '';
      newton = ''
        Address = newton.wak.ioa
        Ed25519PublicKey = Y3l5+f/+GyOKcA99pXN5h2/DY5eYWYGSzVylKlv10lB
        Subnet = 10.2.0.0/16
      '';
      page = ''
        Address = page.wak.io
        Ed25519PublicKey = sGpVBKdBn9ALe7Z6gldb7j2d4v/lAxDfhYpvOn8dFLJ
        Subnet = 10.2.0.0/16
      '';
      quest = ''
        Address = quest.wak.io
        Ed25519PublicKey = nXRjIs3FLanILhsDF36XGq39lnojdL0VJJsvI52cAEA
        Subnet = 10.2.0.0/16
      '';
    }
    (flip mapAttrs vars.vpn.idMap (_: id: ''
      Subnet = ${vars.vpn.subnet}${toString id}/32
    ''))
  ];
}
