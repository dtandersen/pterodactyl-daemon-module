#!/bin/bash
yum update -y -q

sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
setenforce 0

yum install -y yum-utils
yum install -y epel-release https://centos7.iuscommunity.org/ius-release.rpm
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

yum update -y -q

yum install -y -q nano \
  firewalld \
  certbot \
  yum-utils device-mapper-persistent-data lvm2 \
  docker-ce \
  tar unzip make gcc gcc-c++ python \
  nodejs

systemctl enable docker
systemctl start docker

systemctl stop firewalld

certbot certonly --non-interactive --agree-tos --email ${email} --standalone --preferred-challenges http -d ${host}

systemctl start firewalld
systemctl enable firewalld

firewall-cmd --add-port 8080/tcp --permanent
firewall-cmd --add-port 2022/tcp --permanent
firewall-cmd --permanent --zone=trusted --change-interface=docker0
firewall-cmd --reload
mkdir -p /srv/daemon /srv/daemon-data
cd /srv/daemon
curl -Lo daemon.tar.gz https://github.com/Pterodactyl/Daemon/releases/download/v0.6.7/daemon.tar.gz
tar --strip-components=1 -xzvf daemon.tar.gz
npm install --only=production

cat <<'EOF' > /etc/systemd/system/wings.service
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service

[Service]
User=root
#Group=some_group
WorkingDirectory=/srv/daemon
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/bin/node /srv/daemon/src/index.js
Restart=on-failure
StartLimitInterval=600

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable wings
systemctl start wings
