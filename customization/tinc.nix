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
  hosts = {
    jester = ''
      Address = jester.wak.io
      Ed25519PublicKey = Eh3ibLbSRdSdReJTVTzgdJj8nBLjEokdy+/1VaseaLN
    '';
    atomic = ''
      Address = atomic.wak.io
      Ed25519PublicKey = wzPej5rz8cMNWE7YO2DIGUgChZ9CkfYkFIz1J0YCfKP
    '';
    alamo = ''
      Address = alamo.wak.io
      Ed25519PublicKey = 6zMuqE3EAZvc/lZ2FpKoGweT3ihv6Cas4bwHcuU6TGG
    '';
    ferrari = ''
      Ed25519PublicKey = HuyBA/Ol/wH6y4tj4XR6IDI5FLIAcfcdnGXU974K9pC
    '';
    legend = ''
      Ed25519PublicKey = Yqo9IB/XzIA+1QumkTIasL8mFEdd+oc7L3TRLWkxHGH
    '';
    delta = ''
      Ed25519PublicKey = Amd0wHchaDaH25n+4/YEUpCvxDCxjD/vocevi1/wJWB
    '';
    prodigy = ''
      Ed25519PublicKey = kKcEmjbD+1Fx8llu6xlAQsBiuSmb2wJp8PzhAnGtezI
    '';
    newton = ''
      Address = newton.wak.io
      Ed25519PublicKey = Y3l5+f/+GyOKcA99pXN5h2/DY5eYWYGSzVylKlv10lB
    '';
    page = ''
      Address = page.wak.io
      Ed25519PublicKey = sGpVBKdBn9ALe7Z6gldb7j2d4v/lAxDfhYpvOn8dFLJ
    '';
    quest = ''
      Address = quest.wak.io
      Ed25519PublicKey = nXRjIs3FLanILhsDF36XGq39lnojdL0VJJsvI52cAEA
    '';
  };
}
