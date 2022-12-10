#!/bin/sh
while [ -z "$v2rayPath" ]
do
read -p "Enter path (without /): " v2rayPath
done

while [ -z "$v2rayUuid" ]
do
read -p "Enter uuid: " v2rayUuid
done

# domain=${domain:-xxx.com}
# v2rayPath=${v2rayPath}
# v2rayUuid=${v2rayUuid}
v2rayPort=27190

# if [ -z "$path" ]
# then
# echo "path is empty"
# else if [ -z "$uuid" ]
# then
# echo "uuid is empty"
# fi

echo "
path: /${v2rayPath}
uuid: ${v2rayUuid}
"

curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh | bash

apt-get install nginx -y

# echo 'Paste ssl .crt content'
# sslCrt=$(sed '/^$/q')
# echo 'Paste ssl .key content'
# sslKey=$(sed '/^$/q')

# echo "$sslCrt" > /etc/nginx/${domain}_bundle.crt
# echo "$sslKey" > /etc/nginx/${domain}.key

systemctl enable nginx
systemctl enable v2ray
systemctl start nginx
systemctl start v2ray

cat > /usr/local/etc/v2ray/config.json <<EOF
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
            "path": "/${v2rayPath}"
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


cat > /etc/nginx/nginx.conf <<EOF

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
            root   /var/www/html;
            index  index.html index.htm;
        }
				rewrite ^ https:/\$http_host\$request_uri? permanent;
    }
    server {
        listen       443 ssl;
        server_name  localhost;

        ssl_certificate      server.crt;
        ssl_certificate_key  server.key;

        ssl_session_cache    shared:SSL:1m;
        ssl_session_timeout  5m;

        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:HIGH:!aNULL:!MD5:!RC4:!DHE; 
        ssl_prefer_server_ciphers on;
        location / {
            root /var/www/html;
            index  index.html index.htm;
        }
        location /${v2rayPath} {
            proxy_redirect off;
            proxy_pass http://127.0.0.1:${v2rayPort};
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
systemctl restart nginx
systemctl restart v2ray

# BBR 加速
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p # 保存，使更改生效
sysctl net.ipv4.tcp_available_congestion_control # 查看内核是否已开启BBR
lsmod | grep bbr # 查看BBR是否启动


echo "congratulation! config successfully, please reboot"
