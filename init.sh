#!/bin/sh

read -p "Enter domain [xxx.com]: " domain
read -p "Enter path [/something]: " v2rayPath
read -p "Enter uuid: " v2rayUuid

domain=${domain:-abc.com}
v2rayPath=${v2rayPath:-/something}
v2rayUuid=${v2rayUuid:-278b929b-f9f0-4d15-98ca-1e6f31a78073}
v2rayPort=27190

# apt-get install nginx -y
# apt-get install v2ray -y
# systemctl enable nginx
# systemctl enable v2ray
# systemctl start nginx
# systemctl start v2ray

cat > /usr/local/etc/v2ray/config2.json <<EOF
{
  "inbounds": [
    {
      "port": ${v2rayPort},
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": {
        "clients": [{ "id": "${v2rayUuid}", "alterId": 0 }]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
            "path": "${v2rayPath}"
        }
      }
    }
  ],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  }]
}

EOF


cat > /etc/nginx/nginx2.conf <<EOF

#user  nobody;
worker_processes  1;

#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;

#pid        logs/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;
    gzip on;
    gzip_min_length 1k;
    gzip_buffers 4 16k;
    gzip_comp_level 2;
    gzip_types text/plain application/x-javascript text/css application/xml text/javascript application/x-httpd-php image/jpeg image/gif image/png application/javascript;
    gzip_vary off;
    gzip_disable "MSIE [1-6]\.";

    server {
        listen       80;
        server_name  localhost;
        location / {
            root   html;
            index  index.html index.htm;
        }
				rewrite ^ https:/\$http_host\$request_uri? permanent;
    }
    server {
        listen       443 ssl;
        server_name  localhost;

        ssl_certificate      ${domain}_bundle.crt;
        ssl_certificate_key  ${domain}.key;

        ssl_session_cache    shared:SSL:1m;
        ssl_session_timeout  5m;

        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:HIGH:!aNULL:!MD5:!RC4:!DHE; 
        ssl_prefer_server_ciphers on;
        location / {
            root html; 
            index  index.html index.htm;
        }
        location ${v2rayPath} {
            proxy_redirect off;
            proxy_pass http://127.0.0.1:${v2rayPort}
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        }

    }

}
EOF
# systemctl restart nginx
# systemctl restart v2ray
