#!/bin/bash
printf "Welcome to Prometheus manager!\n\n" # print to screen
SYSTEM_ARCH=amd64 #arm64

function usage {
        echo "Usage: $(basename "$0") [-uidnpksv] [-N 1.1.2] [-P 2.27.1] [-r all]" 2>&1
        echo '   -u                         Update node and/or prometheus if specified with corresponding param -n/-p'
        echo '   -i                         Initialize node and/or prometheus if specified with corresponding param -n/-p'
        echo '   -d                         Process node_exporter and prometheus with default version 1.1.2/2.27.1'
        echo '   -n                         Process node_exporter with default version'
        echo '   -N NODE_EXPORTER_VERSION   Specify node_exporter version to be updated'
        echo '   -p                         Process Prometheus with default version'
        echo '   -P PROMETHEUS_VERSION      Specify prometheus version'
        echo '   -k                         Stop systemctl for both prometheus and node_exporter'
        echo '   -s                         Prompt services status'
        echo '   -v                         Get all possible versions'
        echo '   -r all                     Remove all data, users and services'
        exit 1
}

# Set default values
NODE_EXPORTER_VERSION=1.1.2
PROMETHEUS_VERSION=2.27.1

UPDATE_NODE_EXPORTER=false
UPDATE_PROMETHEUS=false

INIT_NODE_EXPORTER=false
INIT_PROMETHEUS=false

NODE_TRIGGER=false
PROMETHEUS_TRIGGER=false

if [[ ${#} -eq 0 ]]; then
   usage
fi

function get_versions() {
  printf "Installation version for node_exporter will be: %s" "$NODE_EXPORTER_VERSION"

  curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest | grep "tag_name" |
  awk '{printf "\nHighest available version for node_exporter is: %s", substr($2, 3, length($2)-4)}'

  printf "\nActual version of node_exporter is:\n"
  /usr/local/bin/node_exporter --version

  printf "\nInstallation version for Prometheus will be: %s" "$PROMETHEUS_VERSION"

  curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | grep "tag_name" |
  awk '{printf "\nHighest available version for Prometheus is: %s\n", substr($2, 3, length($2)-4)}'

  /usr/local/bin/prometheus --version | awk 'NR==1 {printf "Actual version of Prometheus is: %s\n", $3}'
  test -f /usr/local/bin/promtool && echo Promtool is present
}

# Define list of arguments expected in the input
# The following getopts command specifies that options N and P have arguments
optstring=":uidnN:pP:ksvr:"

while getopts ${optstring} arg; do
  case "${arg}" in
    u)
      UPDATE_NODE_EXPORTER=true
      UPDATE_PROMETHEUS=true
      ;;
    i)
      INIT_NODE_EXPORTER=true
      INIT_PROMETHEUS=true
      ;;
    d)
      NODE_TRIGGER=true
      PROMETHEUS_TRIGGER=true
      ;;
    n)
      NODE_TRIGGER=true
      ;;
    N)
      NODE_EXPORTER_VERSION="${OPTARG}"
      NODE_TRIGGER=true
      ;;
    p)
      PROMETHEUS_TRIGGER=true
      ;;
    P)
      PROMETHEUS_VERSION="${OPTARG}"
      PROMETHEUS_TRIGGER=true
      ;;
    k)
      systemctl stop node_exporter
      systemctl stop prometheus
      exit 1
      ;;
    s)
      systemctl status node_exporter | awk 'NR==3 {printf "\nStatus of node_exporter: %s\n", $2}'
      systemctl status prometheus | awk 'NR==3 {printf "Status of Prometheus: %s\n", $2}'
      exit 1
      ;;
    v)
      get_versions
      exit 1
      ;;
    r)
      systemctl stop node_exporter
      systemctl stop prometheus
      rm /usr/local/bin/node_exporter
      rm /etc/systemd/system/node_exporter.service
      rm /usr/local/bin/prometheus
      rm /usr/local/bin/promtool
      rm -rf /etc/prometheus
      rm -rf /var/lib/prometheus/
      rm /etc/systemd/system/prometheus.service
      deluser --remove-home node_exporter
      deluser --remove-home prometheus
      systemctl daemon-reload
      exit 1
      ;;
    ?)
      echo "Invalid option: -${OPTARG}."
      echo
      usage
      ;;
  esac
done


useradd --no-create-home --shell /usr/sbin/nologin prometheus &> /dev/null || grep prometheus /etc/passwd
useradd --no-create-home --shell /bin/false node_exporter &> /dev/null || grep node_exporter /etc/passwd

mkdir /etc/prometheus &> /dev/null
mkdir /var/lib/prometheus &> /dev/null
ls /etc | grep prometheus | awk '{printf "\nDirectories %s:\n", $1}'
chown prometheus:prometheus /etc/prometheus &> /dev/nul4l && ls -all /etc | grep prometheus
chown prometheus:prometheus /var/lib/prometheus && ls -all /var/lib/ | grep prometheus

if $UPDATE_NODE_EXPORTER && $NODE_TRIGGER; then
  printf "\nUpdate node_exporter\n"
  test -f node_exporter-${NODE_EXPORTER_VERSION}.linux-${SYSTEM_ARCH}.tar.gz || wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-${SYSTEM_ARCH}.tar.gz

  tar xfz node_exporter-*.tar.gz &> /dev/null
  cp node_exporter-${NODE_EXPORTER_VERSION}.linux-${SYSTEM_ARCH}/node_exporter /usr/local/bin
  chown node_exporter:node_exporter /usr/local/bin/node_exporter

  rm -rf node_exporter-${NODE_EXPORTER_VERSION}*
fi

if $INIT_NODE_EXPORTER && $NODE_TRIGGER; then
  cat > /etc/systemd/system/node_exporter.service <<EOM
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter \
  --collector.systemd \
  --collector.processes \
  --web.listen-address=:9500

[Install]
WantedBy=multi-user.target
EOM

  systemctl daemon-reload
  systemctl enable node_exporter
  systemctl start node_exporter
fi

systemctl status node_exporter | awk 'NR==3 {printf "\nStatus of node_exporter: %s\n", $2}'

if $UPDATE_PROMETHEUS && $PROMETHEUS_TRIGGER; then
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

if $INIT_PROMETHEUS && $PROMETHEUS_TRIGGER; then
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
      - targets: ['localhost:9590']

  - job_name: 'node_exporter'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9500']
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
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.listen-address=:9590
  ExecReload=/bin/kill -HUP $MAINPID

[Install]
  WantedBy=multi-user.target
EOM

  systemctl daemon-reload
  systemctl enable prometheus
  systemctl start prometheus
fi

systemctl status prometheus | awk 'NR==3 {printf "\nStatus of Prometheus: %s\n", $2}'

get_versions