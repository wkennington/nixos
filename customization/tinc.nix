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
    "legend"
  ];
  hosts = {
    atomic = ''
      Address = atomic.wak.io
      Ed25519PublicKey = CyQA7TSZ1hksT5YlM6JA1ZKsGwy4wufkG2UDg8+BGaA
    '';
    prodigy = ''
      Ed25519PublicKey = kKcEmjbD+1Fx8llu6xlAQsBiuSmb2wJp8PzhAnGtezI
    '';
    lotus = ''
      Ed25519PublicKey = M0pHIXS55y831Hhs4zvB8PbdBfXV6T5hFMRSYMW8WeC
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
    legend = ''
      Address = lazarus.wak.io
      Ed25519PublicKey = zSAeyznGvqmaQAOmv9F4LOQGWpGQJNGGzP5DrEK9tAE
      Subnet = 10.1.0.0/16
    '';
  };
}
