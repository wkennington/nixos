{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [ mosh ];
  networking.firewall.allowedUDPPortRanges = [
    { from = 60000; to = 61000; }
  ];
  services.openssh = {
    enable = true;
    hostKeys = [
      { path = "/etc/ssh/ssh_host_rsa_key"; type = "rsa"; bits = 4096; }
      { path = "/etc/ssh/ssh_host_ed25519_key"; type = "ed25519"; bits = 256; }
    ];
    forwardX11 = false;
    passwordAuthentication = false;
    challengeResponseAuthentication = false;
    extraConfig = pkgs.lib.mkAfter ''
      AllowAgentForwarding yes
      AllowTcpForwarding no
      PrintMotd no
      UseDNS no

      Ciphers aes256-gcm@openssh.com
      KexAlgorithms curve25519-sha256@libssh.org
      MACs hmac-sha2-512-etm@openssh.com

      Match User root
        AllowTcpForwarding yes
    '';
  };
  users.extraUsers = {
    root.openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCImsGRStNDeIj3jKadRs021MjYS+UuDkvFymDdPzwAPq9eB4WEA+nO82YUa3f3Cwq3tAjc7rbwD6BuQMPcKDNXYdxdZf9Ddv+2XprFBXmLM6IMytwXvW8GC6cUraHMWHQDwJLEZfcazX/KGFrcuAqRlUrLRttUEZ4BFadrjwkJF+JFycy64JRNlypKUtv5RYaZpFiVOs498KD96H7dU59d+vUb+OB/5rLgeE+495lKpTwlNYwsckhAoaFidJK3pSI0L1gfyVQ66+LLtMnxyjt4jauVa12qyQLwgqBCjAZbR54cmRrN+z9UKBEpS+F418i7+dfH3L2feLnAMA7bAAgK38XF4TqSr6o7+GZbyotHg1T+4YwbjwIqI3RVSJ828wgXhmwnOUtsjyMAe4rMta4UMrDIxJ8FI6e+S/mICeXhl6r7Z6+pz0XyyKjd8Qy32yuU/Fyd8Gl79UsDx1vR/f9B8faUR5Nxig9Xec+ob9b9OLsd514pkoszeVtnBF1rq1qXsg/YsNigGp06CgD/YaqyQO4OLIcK7Z1VzyJo+Q2GI7Qou7g+8A5uStO0TkCYGcg9SrU1tKP+mGY21N+jvaQLBx9/yEkXITM2cl+9rKVZb12lH2afTgzGmU4xGUx61yi6XxcASpTxKSyYfsRXrwqCmyUXZxNt5QWnF4EQAMzIKQ== Gemalto Smartcard"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCR4V6j9qhiZ/P6CodO7P8nWjqZSbD/gVlKZMlc+AusK5gVhHjjL8QG1OQ9hPn63K4kQ5Ohi+1U9bqKxVcSMNudumv0BsGKhA/ZndGlAWXV/euahSiIEfLYREoV7FcBXCyo+e1+ir1JUUuPUh/K84SINxmKbr7hA33dNkZMlnfWy8ZcZ1BklbUWWh/zCj59b9dqUzEATulUQWO/URTTh51tMTR8Hn9eFHooQzv4QCyQnMG3eULMhxrqHCal2bCn67u7Xn9oPKoAkKgUWisJdqhPKSJjeR80IFSDsb0RqmLI/KnrVULxLakM9E7DOl1Nwd8bxurKt/EcOrZtAP+O4SYx Keychain Yubikey"
    ];
  };
}
