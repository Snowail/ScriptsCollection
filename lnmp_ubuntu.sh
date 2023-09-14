#!/usr/bin/env bash
# Copyright (C) 2023 Snowail <yukine@snowail.me>
# 
# This script will install Nginx + PHP + MariaDB on ubuntu 20.02+
# 自用脚本

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# 指定php版本
export PHPVER=8.1

# 更新软件源
apt update && apt upgrad
# 安装软件源拓展工具
apt -y install software-properties-common apt-transport-https lsb-release ca-certificates
# 安装LNMP
apt install nginx php$PHPVER-fpm php$PHPVER-curl php$PHPVER-gd php$PHPVER-gmp php$PHPVER-imap php$PHPVER-mbstring php$PHPVER-mysql php$PHPVER-sqlite3 php$PHPVER-intl php$PHPVER-imagick php$PHPVER-xml php$PHPVER-xmlrpc php$PHPVER-zip php$PHPVER-bcmath php$PHPVER-redis redis imagemagick mariadb-server mariadb-client

#编辑php.ini配置
# 修改限制
sed -i '/max_execution_time*/c\max_execution_time = 300'  /etc/php/$PHPVER/fpm/php.ini
sed -i '/max_input_time*/c\max_input_time = 300'  /etc/php/$PHPVER/fpm/php.ini
sed -i '/;max_input_vars*/c\max_input_vars = 2048'  /etc/php/$PHPVER/fpm/php.ini
sed -i '/memory_limit*/c\memory_limit = 256'  /etc/php/$PHPVER/fpm/php.ini
sed -i '/post_max_size*/c\post_max_size = 50M' /etc/php/$PHPVER/fpm/php.ini
sed -i '/upload_max_filesize*/c\upload_max_filesize = 50M' /etc/php/$PHPVER/fpm/php.ini

# 开启opcache
sed -i 's#;opcache.enable=[0-1]#opcache.enable=1#' /etc/php/$PHPVER/fpm/php.ini
sed -i 's#;opcache.enable_cli=[0-1]#opcache.enable_cli =1#' /etc/php/$PHPVER/fpm/php.ini
sed -i 's#;opcache.memory_consumption#opcache.memory_consumption#' /etc/php/$PHPVER/fpm/php.ini
sed -i 's#;opcache.interned_strings_buffer#opcache.interned_strings_buffer#' /etc/php/$PHPVER/fpm/php.ini
sed -i 's#;opcache.max_accelerated_files#opcache.max_accelerated_files#' /etc/php/$PHPVER/fpm/php.ini
sed -i 's#;opcache.save_comments#opcache.save_comments#' /etc/php/$PHPVER/fpm/php.ini
sed -i 's#;opcache.revalidate_freq=[0-9]#opcache.revalidate_freq=1#' /etc/php/$PHPVER/fpm/php.ini

# for wordpress cgi.fix_pathinfo = 0
sed -i 's#;cgi.fix_pathinfo=[0-9]#cgi.fix_pathinfo=0#' /etc/php/$PHPVER/fpm/php.ini

systemctl restart php$PHPVER-fpm

# 在php-fpm.conf中添加PATH变量
sed -i 's#;clear_env#clear_env#'  /etc/php/$PHPVER/fpm/pool.d/www.conf
sed -i 's#;env\[PATH\] = /usr/local/bin:/usr/bin:/bin#env\[PATH\] = /usr/local/bin:/usr/bin:/bin:/usr/local/php/bin#'  /etc/php/$PHPVER/fpm/pool.d/www.conf

# 修复权限
chown -R www-data /var/www
chmod -R 755 /var/www

# 配置NGINX
sed -i "s/^.*worker_connections.*$/worker_connections 1024;/" /etc/nginx/nginx.conf
sed -i '23 i \    client_max_body_size 0;' /etc/nginx/nginx.conf
sed -i "33 i \    upstream php {\n      server unix:/run/php/php$PHPVER-fpm.sock\n}" /etc/nginx/nginx.conf

# 创建通用配置目录
mkdir /etc/nginx/cert
mkdir /etc/nginx/global
# 创建CloudFlare白名单
cat > /etc/nginx/global/cf.conf << EOF
# https://www.cloudflare.com/ips
# IPv4
allow 173.245.48.0/20;
allow 103.21.244.0/22;
allow 103.22.200.0/22;
allow 103.31.4.0/22;
allow 141.101.64.0/18;
allow 108.162.192.0/18;
allow 190.93.240.0/20;
allow 188.114.96.0/20;
allow 197.234.240.0/22;
allow 198.41.128.0/17;
allow 162.158.0.0/15;
allow 104.16.0.0/13;
allow 104.24.0.0/14;
allow 172.64.0.0/13;
allow 131.0.72.0/22;
# IPv6
allow 2400:cb00::/32;
allow 2606:4700::/32;
allow 2803:f800::/32;
allow 2405:b500::/32;
allow 405:8100::/32;
allow 2a06:98c0::/29;
allow 2c0f:f248::/32;
EOF
