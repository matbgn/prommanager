#!/bin/bash
printf "Welcome to Prometheus manager!\n\n" # print to screen
SYSTEM_ARCH=amd64 #arm64

UPDATE_NODE_EXPORTER=false
NODE_EXPORTER_VERSION=1.1.2
INIT_NODE_EXPORTER=false

UPDATE_PROMETHEUS=false
PROMETHEUS_VERSION=2.27.1
INIT_PROMETHEUS=false

useradd --no-create-home --shell /usr/sbin/nologin prometheus &> /dev/null || grep prometheus /etc/passwd
useradd --no-create-home --shell /bin/false node_exporter &> /dev/null || grep node_exporter /etc/passwd

(mkdir /etc/prometheus && mkdir /var/lib/prometheus) &> /dev/null
ls /etc | grep prometheus | awk '{printf "\nDirectories %s exists:\n", $1}'
chown prometheus:prometheus /etc/prometheus &> /dev/nul4l && ls -all /etc | grep prometheus
chown prometheus:prometheus /var/lib/prometheus && ls -all /var/lib/ | grep prometheus

if $UPDATE_NODE_EXPORTER; then
  printf "\nUpdate node_exporter\n"
  test -f node_exporter-${NODE_EXPORTER_VERSION}.linux-${SYSTEM_ARCH}.tar.gz || wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-${SYSTEM_ARCH}.tar.gz

  tar xfz node_exporter-*.tar.gz &> /dev/null
  cp node_exporter-${NODE_EXPORTER_VERSION}.linux-${SYSTEM_ARCH}/node_exporter /usr/local/bin
  chown node_exporter:node_exporter /usr/local/bin/node_exporter

  rm -rf node_exporter-${NODE_EXPORTER_VERSION}*
fi

printf "\nVersion of node_exporter is:\n"
/usr/local/bin/node_exporter --version

if $INIT_NODE_EXPORTER; then
  cat > /etc/systemd/system/node_exporter.service <<EOM
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter --collector.systemd --collector.processes

[Install]
WantedBy=multi-user.target
EOM

  systemctl daemon-reload
  systemctl enable node_exporter
  systemctl start node_exporter
fi

systemctl status node_exporter | awk 'NR==3 {printf "\nStatus of node_exporter: %s\n", $2}'

if $UPDATE_PROMETHEUS; then
  printf "\nUpdate Prometheus\n"
  test -f prometheus-${PROMETHEUS_VERSION}.linux-${SYSTEM_ARCH}.tar.gz || wget https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-${SYSTEM_ARCH}.tar.gz

  tar xfz prometheus-*.tar.gz &> /dev/null
  cp prometheus-${PROMETHEUS_VERSION}.linux-${SYSTEM_ARCH}/prometheus /usr/local/bin
  cp prometheus-${PROMETHEUS_VERSION}.linux-${SYSTEM_ARCH}/promtool /usr/local/bin
  chown prometheus:prometheus /usr/local/bin/prometheus
  chown prometheus:prometheus /usr/local/bin/promtool

  cp -r prometheus-${PROMETHEUS_VERSION}.linux-${SYSTEM_ARCH}/consoles /etc/prometheus
  cp -r prometheus-${PROMETHEUS_VERSION}.linux-${SYSTEM_ARCH}/console_libraries /etc/prometheus
  chown -R prometheus:prometheus /etc/prometheus/consoles
  chown -R prometheus:prometheus /etc/prometheus/console_libraries

  rm -rf prometheus-${PROMETHEUS_VERSION}*
fi

/usr/local/bin/prometheus --version | awk 'NR==1 {printf "\nVersion of Prometheus is: %s\n", $3}'
test -f /usr/local/bin/promtool && echo Promtool is present

if $INIT_PROMETHEUS; then
  cat > /etc/prometheus/prometheus.yml <<EOM
global:
  scrape_interval:     15s
  evaluation_interval: 15s

rule_files:
  # - "first.rules"
  # - "second.rules"

scrape_configs:
  - job_name: 'prometheus'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node_exporter'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9100']
EOM

cat > /etc/systemd/system/prometheus.service <<EOM
[Unit]
  Description=Prometheus Monitoring
  Wants=network-online.target
  After=network-online.target

[Service]
  User=prometheus
  Group=prometheus
  Type=simple
  ExecStart=/usr/local/bin/prometheus \
  --config.file /etc/prometheus/prometheus.yml \
  --storage.tsdb.path /var/lib/prometheus/ \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries
  ExecReload=/bin/kill -HUP $MAINPID

[Install]
  WantedBy=multi-user.target
EOM

  systemctl daemon-reload
  systemctl enable prometheus
  systemctl start prometheus
fi

systemctl status prometheus | awk 'NR==3 {printf "\nStatus of Prometheus: %s\n", $2}'
