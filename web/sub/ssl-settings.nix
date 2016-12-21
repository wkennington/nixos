{ domain }:
''
  ssl on;
  ssl_protocols TLSv1.2;
  ssl_ciphers EECDH+CHACHA20:EECDH+AESGCM;
  ssl_ecdh_curve secp384r1;
  ssl_prefer_server_ciphers on;
  ssl_certificate /conf/ssl/${domain}.crt;
  ssl_certificate_key /conf/ssl/${domain}.key;
  ssl_session_cache builtin:1000 shared:SSL:10m;
  ssl_session_ticket_key /conf/ssl/nginx/ticket1.key;
  ssl_session_ticket_key /conf/ssl/nginx/ticket2.key;
  ssl_session_tickets on;
  ssl_session_timeout 10m;
  ssl_stapling on;
  ssl_stapling_verify on;
  resolver 127.0.0.1;
  add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
''
