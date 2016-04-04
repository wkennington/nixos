{ domain }:
''
  ssl on;
  ssl_protocols TLSv1.2;
  ssl_ciphers EECDH+AESGCM;
  ssl_ecdh_curve secp384r1;
  ssl_prefer_server_ciphers on;
  ssl_certificate /conf/ssl/${domain}.crt;
  ssl_certificate_key /conf/ssl/${domain}.key;
  add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload";
''
