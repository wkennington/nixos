{ lib, ... }:
let
  vars = (import ./vars.nix { inherit lib; });
in
with lib;
{
  dedicated = [
    "atomic"
    "newton"
    "page"
    "quest"
    "exodus"
  ];
  hosts = {
    atomic = ''
      Address = atomic.wak.io
      Ed25519PublicKey = wzPej5rz8cMNWE7YO2DIGUgChZ9CkfYkFIz1J0YCfKP
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
    exodus = ''
      Address = lb.mtv-w.wak.io
      Ed25519PublicKey = LIkjY1u8bIHOWqM6Y+5cP6kGecMRLRRH/WbMgCkpEEL
      Subnet = 10.1.0.0/16
    '';
  };
}
