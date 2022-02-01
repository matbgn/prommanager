#!/bin/bash
printf "Welcome to Prometheus manager!\n\n" # print to screen

# Set default values
SYSTEM_ARCH=amd64 # -> can be changed by script argument -a arm64

NODE_EXPORTER_VERSION=1.3.0 # -> can be changed by script argument -N 1.1.2
PROMETHEUS_VERSION=2.31.1 # -> can be changed by script argument -P 2.27.1

NODE_EXPORTER_PORT=9500
PROMETHEUS_PORT=9590

UPDATE_NODE_EXPORTER=false # -> can be changed by script argument -u
UPDATE_PROMETHEUS=false # -> can be changed by script argument -u

INIT_NODE_EXPORTER=false # -> can be changed by script argument -i
INIT_PROMETHEUS=false # -> can be changed by script argument -i

NODE_TRIGGER=false # -> can be changed either by script argument -n or -N 1.1.2 or -b
PROMETHEUS_TRIGGER=false # -> can be changed either by script argument -p or -P 2.27.1 or -b


function usage {
        echo "Usage: $(basename "$0") [-uilbnpksv] [-a arm64] [-N 1.1.2] [-P 2.27.1] [-r all]" 2>&1
        echo '   -a arm64                   Set architecture, default is amd64'
        echo '   -u                         Update node and/or prometheus if specified with corresponding param -n/-p/-b'
        echo '   -i                         Initialize node and/or prometheus if specified with corresponding param -n/-p/-b'
        echo '   -l                         List all ports used'
        echo '   -b                         Process both node_exporter and prometheus with default script version'
        echo '   -n                         Process node_exporter with default script version'
        echo '   -N 1.1.2                   Specify node_exporter version'
        echo '   -p                         Process Prometheus with default script version'
        echo '   -P 2.27.1                  Specify prometheus version'
        echo '   -k                         Stop daemons for both prometheus and node_exporter'
        echo '   -s                         Prompt services status'
        echo '   -v                         Get all possible versions'
        echo '   -r all                     Remove all data, users and services'
        exit 1
}

# Define list of arguments expected in the input
# The following getopts command specifies that options N and P have arguments
OPTSTRING=":a:uilbnN:pP:ksvr:"

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
  echo
}


function get_status() {

  systemctl 2>/dev/null
  if [ $? -eq 0 ]
  then

    if systemctl status node_exporter | grep 'failed' > /dev/null
    then
      printf "\nStatus of node_exporter: \n"
      systemctl status node_exporter &
      disown
      sleep 0.5
      kill "$!"
      stty sane
    else
      systemctl status node_exporter | awk 'NR==3 {printf "Status of node_exporter: %s\n", $2}'
    fi
    echo


    if systemctl status prometheus | grep 'failed' > /dev/null
    then
      printf "\nStatus of Prometheus: \n"
      systemctl status prometheus &
      disown
      sleep 0.5
      kill "$!"
      stty sane
    else
      systemctl status prometheus | awk 'NR==3 {printf "Status of Prometheus: %s\n", $2}'
    fi
    echo

  else

    if service node_exporter status | grep 'failed' > /dev/null
    then
      printf "\nStatus of node_exporter: \n"
      service node_exporter status &
      disown
      sleep 0.5
      kill "$!"
      stty sane
    else
      service node_exporter status | awk 'NR==3 {printf "Status of node_exporter: %s\n", $2}'
    fi
    echo


    if service node_exporter status | grep 'failed' > /dev/null
    then
      printf "\nStatus of Prometheus: \n"
      service prometheus status &
      disown
      sleep 0.5
      kill "$!"
      stty sane
    else
      service prometheus status | awk 'NR==3 {printf "Status of Prometheus: %s\n", $2}'
    fi
    echo

  fi
}

function list_used_ports() {
  if ! command -v netstat &> /dev/null
  then
    echo "Netstat could not be found, install it first (via net-tools package)!"
    echo
    exit
  else
    printf "Actual ports used on this machine:\n"
    netstat -plnt
    echo
  fi
}


function set_users() {
  useradd --no-create-home --shell /usr/sbin/nologin prometheus &> /dev/null || grep prometheus /etc/passwd
  useradd --no-create-home --shell /bin/false node_exporter &> /dev/null || grep node_exporter /etc/passwd
  echo
}


function update_node_exporter() {
  printf "Update node_exporter\n"
  test -f node_exporter-${NODE_EXPORTER_VERSION}.linux-${SYSTEM_ARCH}.tar.gz || curl -OL https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-${SYSTEM_ARCH}.tar.gz

  tar xfz node_exporter-*.tar.gz &> /dev/null
  cp node_exporter-${NODE_EXPORTER_VERSION}.linux-${SYSTEM_ARCH}/node_exporter /usr/local/bin
  chown node_exporter:node_exporter /usr/local/bin/node_exporter

  rm -rf node_exporter-${NODE_EXPORTER_VERSION}*
}


function init_node_exporter() {
  systemctl 2>/dev/null
  if [ $? -eq 0 ]
  then

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
  --web.listen-address=:${NODE_EXPORTER_PORT}

[Install]
WantedBy=multi-user.target
EOM


    systemctl daemon-reload
    systemctl enable node_exporter
    systemctl start node_exporter
  else
    printf "You have to install node_exporter daemon manually!\nSee for instance ruby gem pleaserun https://github.com/jordansissel/pleaserun"
  fi
}


function set_prometheus_folders() {
  mkdir /etc/prometheus &> /dev/null
  mkdir /var/lib/prometheus &> /dev/null
  ls /etc | grep prometheus | awk '{printf "Directories %s:\n", $1}'
  chown prometheus:prometheus /etc/prometheus &> /dev/null && ls -all /etc | grep prometheus
  chown prometheus:prometheus /var/lib/prometheus && ls -all /var/lib/ | grep prometheus
  echo
}


function update_prometheus() {
  printf "Update Prometheus\n"
  test -f prometheus-${PROMETHEUS_VERSION}.linux-${SYSTEM_ARCH}.tar.gz || curl -OL https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-${SYSTEM_ARCH}.tar.gz

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
}


function init_prometheus() {
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
      - targets: ['localhost:${PROMETHEUS_PORT}']

  - job_name: 'node_exporter'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:${NODE_EXPORTER_PORT}']
EOM

  systemctl 2>/dev/null
  if [ $? -eq 0 ]
  then

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
  --web.listen-address=:${PROMETHEUS_PORT}
  ExecReload=/bin/kill -HUP ${MAINPID}

[Install]
  WantedBy=multi-user.target
EOM

    systemctl daemon-reload
    systemctl enable prometheus
    systemctl start prometheus
  else
    printf "You have to install prometheus daemon manually!\nSee for instance ruby gem pleaserun https://github.com/jordansissel/pleaserun"
  fi
}


while getopts ${OPTSTRING} arg; do
  case "${arg}" in
    a)
      SYSTEM_ARCH="${OPTARG}"
      ;;
    b)
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
    u)
      UPDATE_NODE_EXPORTER=true
      UPDATE_PROMETHEUS=true
      ;;
    i)
      INIT_NODE_EXPORTER=true
      INIT_PROMETHEUS=true
      ;;
    l)
      list_used_ports
      ;;
    v)
      get_versions
      ;;
    s)
      get_status
      ;;
    k)
      systemctl 2>/dev/null
      if [ $? -eq 0 ]
      then
        systemctl stop node_exporter
        systemctl stop prometheus
      else
        service node_exporter stop
        service prometheus stop
      fi
      get_status
      exit 1
      ;;
    r)
      systemctl 2>/dev/null
      if [ $? -eq 0 ]
      then
        systemctl stop node_exporter
        systemctl stop prometheus
      else
        service node_exporter stop
        service prometheus stop
      fi
      rm /usr/local/bin/node_exporter
      rm /usr/local/bin/prometheus
      rm /usr/local/bin/promtool
      rm -rf /etc/prometheus
      rm -rf /var/lib/prometheus/

      deluser --remove-home node_exporter
      deluser --remove-home prometheus

      systemctl 2>/dev/null
      if [ $? -eq 0 ]
      then
        rm /etc/systemd/system/node_exporter.service
        rm /etc/systemd/system/prometheus.service
        systemctl daemon-reload
      else
        printf "You have to remove daemons node_exporter & prometheus manually!"
      fi

      exit 1
      ;;
    ?)
      echo "Invalid option: -${OPTARG}."
      echo
      usage
      ;;
  esac
done

# Initial jobs to ensure script working smoothly
# shellcheck disable=SC2199
if [[ ${@} == *u* || ${@} == *i* ]]; then
  set_users
  set_prometheus_folders
fi

if $UPDATE_NODE_EXPORTER && $NODE_TRIGGER; then
  update_node_exporter
fi
if $UPDATE_PROMETHEUS && $PROMETHEUS_TRIGGER; then
  update_prometheus
fi

if $INIT_NODE_EXPORTER && $NODE_TRIGGER; then
  init_node_exporter
fi
if $INIT_PROMETHEUS && $PROMETHEUS_TRIGGER; then
  init_prometheus
fi

# shellcheck disable=SC2199
if [[ ${@} == *u* || ${@} == *i* ]]; then
  get_status
fi
