#!/bin/bash
MODT="Welcome to Prometheus manager v1.0.0!"

# Set default values
SYSTEM_ARCH=amd64 # -> can be changed by script argument -a arm64

LOG_LEVEL=0

DEBUG_OFFLINE=false

# Retrieve versions from .versions file in form of:
# NODE_EXPORTER_VERSION=1.3.1
# PROMETHEUS_VERSION=2.33.5
file=$(cat .versions)
for line in $file
do
    eval "${line%=*}"="${line##*=}"
done

DISPLAY_VERSIONS=false
DISPLAY_NODE_EXPORTER=false
DISPLAY_BLACKBOX_EXPORTER=false
DISPLAY_PROMETHEUS=false
DISPLAY_ALERTMANAGER=false

UPDATE_VERSIONS=false
UPDATE_NODE_EXPORTER=false
UPDATE_BLACKBOX_EXPORTER=false
UPDATE_PROMETHEUS=false
UPDATE_ALERTMANAGER=false

INSTALL=false

EXECUTE=false

NODE_EXPORTER_PORT=9500
PROMETHEUS_PORT=9590

NODE_TRIGGER=false # -> can be changed either by script argument -n or -N 1.1.2 or -b
PROMETHEUS_TRIGGER=false # -> can be changed either by script argument -p or -P 2.27.1 or -b

function usage {
        echo "Usage: $(basename "$0") [<flags>]" 2>&1
        echo '   -h, --help                          Show this help context'
        echo '   -v, --verbose                       Adaptative verbose mode (-vv for WARN, -vvv for INFO, -vvvv for full debugging)'
        echo '   -V, --versions [all|<app>]          Display versions of all available apps (prometheus, node_exporter, etc.)'
        echo '   -U, --update-versions [all|<app>]   Retrieve and override versions numbers for selected apps (prometheus, node_exporter, etc.)'
        echo '   -s, --status                        Prompt services status'
        echo '   --ports                             List all ports actually used'
        echo '   --arch arm64                        Set architecture, default is amd64'
        echo '   -I, --install                       Install services combined with corresponding params e.g. --all'
        echo '   -E, --exec                          Execute services combined with corresponding params e.g. --all'
        echo '   --all                               Process script for all available apps (prometheus, node_exporter, etc.)'
        echo '   -n, --node                          Process for node_exporter'
        echo '   -N [<version>]                      Specify node_exporter version'
        echo '   -p, --prom                          Process for Prometheus'
        echo '   -P [<version>]                      Specify prometheus version'
        echo '   -k, --kill                          Stop daemons for both prometheus and node_exporter'
        echo '   --remove-all                        Remove all data, users and services'
        echo '   --offline                           For debug purpose only'
        exit 1
}


function flags() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      -h|--help)
        usage
        exit 1
        ;;
      -v|--verbose)
        LOG_LEVEL=1
        shift # argument
        ;;
      -vv)
        LOG_LEVEL=2
        shift # argument
        ;;
      -vvv)
        LOG_LEVEL=3
        shift # argument
        ;;
      -vvvv)
        LOG_LEVEL=4
        shift # argument
        ;;
      -V|--versions)
        check_options_mandatory "$2"
        DISPLAY_VERSIONS_SELECTION="$2"
        DISPLAY_VERSIONS=true
        shift # argument
        shift # value
        if [ "$DISPLAY_VERSIONS_SELECTION" == "all" ]
        then
          DISPLAY_NODE_EXPORTER=true
          DISPLAY_BLACKBOX_EXPORTER=true
          DISPLAY_PROMETHEUS=true
          DISPLAY_ALERTMANAGER=true
        fi
        if [ "$DISPLAY_VERSIONS_SELECTION" == "node" ]
        then
          DISPLAY_NODE_EXPORTER=true
        fi
        if [ "$DISPLAY_VERSIONS_SELECTION" == "blackbox" ]
        then
          DISPLAY_BLACKBOX_EXPORTER=true
        fi
        if [ "$DISPLAY_VERSIONS_SELECTION" == "prom" ]
        then
          DISPLAY_PROMETHEUS=true
        fi
        if [ "$DISPLAY_VERSIONS_SELECTION" == "alert" ]
        then
          DISPLAY_ALERTMANAGER=true
        fi
        ;;
      -U|--update-versions)
        check_options_mandatory "$2"
        UPDATE_VERSIONS_SELECTION="$2"
        UPDATE_VERSIONS=true
        shift # argument
        shift # value
        if [ "$UPDATE_VERSIONS_SELECTION" == "all" ]
        then
          UPDATE_NODE_EXPORTER=true
          UPDATE_BLACKBOX_EXPORTER=true
          UPDATE_PROMETHEUS=true
          UPDATE_ALERTMANAGER=true
        fi
        if [ "$UPDATE_VERSIONS_SELECTION" == "node" ]
        then
          UPDATE_NODE_EXPORTER=true
        fi
        if [ "$UPDATE_VERSIONS_SELECTION" == "blackbox" ]
        then
          UPDATE_BLACKBOX_EXPORTER=true
        fi
        if [ "$UPDATE_VERSIONS_SELECTION" == "prom" ]
        then
          UPDATE_PROMETHEUS=true
        fi
        if [ "$UPDATE_VERSIONS_SELECTION" == "alert" ]
        then
          UPDATE_ALERTMANAGER=true
        fi
        ;;
      -s|--status)
        get_status
        shift # argument
        ;;
      --ports)
        list_used_ports
        shift # argument
        ;;
      --arch)
        check_options_mandatory "$2"
        SYSTEM_ARCH="$2"
        shift # argument
        shift # value
        ;;
      -I|--install)
        INSTALL=true
        shift # argument
        ;;
      -E|--exec)
        EXECUTE=true
        shift # argument
        ;;
      --all)
        NODE_TRIGGER=true
        PROMETHEUS_TRIGGER=true
        shift # argument
        ;;
      -n|--node)
        NODE_TRIGGER=true
        shift # argument
        ;;
      -N)
        check_options_mandatory "$2"
        NODE_EXPORTER_VERSION="$2"
        NODE_TRIGGER=true
        shift # argument
        shift # value
        ;;
      -p|--prom)
        PROMETHEUS_TRIGGER=true
        shift # argument
        ;;
      -P)
        check_options_mandatory "$2"
        PROMETHEUS_VERSION="$2"
        PROMETHEUS_TRIGGER=true
        shift # argument
        shift # value
        ;;
      -k|--kill)
        systemctl >/dev/null 2>&1
        if [ $? -eq 0 ]
        then
          systemctl stop node_exporter
          systemctl stop prometheus
        else
          service node_exporter stop
          service prometheus stop
        fi
        echo
        get_status
        exit 1
        ;;
      --remove-all)
        systemctl >/dev/null 2>&1
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

        systemctl >/dev/null 2>&1
        if [ $? -eq 0 ]
        then
          rm /etc/systemd/system/node_exporter.service
          rm /etc/systemd/system/prometheus.service
          systemctl daemon-reload
        else
          rm /etc/init.d/node_exporter
          rm /etc/default/node_exporter
          rm /etc/init.d/prometheus
          rm /etc/default/prometheus
          update-rc.d node_exporter remove
          update-rc.d prometheus remove
        fi

        exit 1
        ;;
      --offline)
        DEBUG_OFFLINE=true
        shift # argument
        ;;
      -*|--*)
        echo "Unknown option $1"
        exit 1
        ;;
      *)
        POSITIONAL_ARGS+=("$1") # save positional arg
        shift # past argument
        ;;
    esac
  done
}


function check_options_mandatory() {
    if [ "${1::1}" == "-" ]
    then
      echo "Value is mandatory for argument before $1"
      exit 1
    fi

    if [ -z "$1" ]
    then
      echo "Value is mandatory for final argument"
      exit 1
    fi
}


function check_root_rights(){
  if [ `id -u` -ne 0 ]
  then
    echo "[ERROR] This script require sudo rights to run smoothly"
  fi
}


function retrieve_node_version() {
    if [ $LOG_LEVEL -gt 3 ]
    then
      echo '[DEBUG] Retrieving node_exporter version...'
    fi
    NODE_EXPORTER_VERSION_CURLED="$(curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest |
    grep 'tag_name' | awk '{printf substr($2, 3, length($2)-4)}')"

    if [[ -z $NODE_EXPORTER_VERSION_CURLED ]]
    then
      echo '[ERROR] System was not able to retrieve node_exporter version check your internet connection'
      exit 1
    fi

    if [ $LOG_LEVEL -gt 2 ]
    then
      echo "[INFO] node_exporter version retrieved: " "$NODE_EXPORTER_VERSION_CURLED"
    fi
}


function retrieve_blackbox_version() {
    if [ $LOG_LEVEL -gt 3 ]
    then
      echo '[DEBUG] Retrieving blackbox_exporter version...'
    fi
    BLACKBOX_EXPORTER_VERSION_CURLED="$(curl -s https://api.github.com/repos/prometheus/blackbox_exporter/releases/latest |
    grep 'tag_name' | awk '{printf substr($2, 3, length($2)-4)}')"

    if [[ -z $BLACKBOX_EXPORTER_VERSION_CURLED ]]
    then
      echo '[ERROR] System was not able to retrieve blackbox_exporter version check your internet connection'
      exit 1
    fi

    if [ $LOG_LEVEL -gt 2 ]
    then
      echo "[INFO] blackbox_exporter version retrieved: " "$BLACKBOX_EXPORTER_VERSION_CURLED"
    fi
}


function retrieve_prometheus_version() {
    if [ $LOG_LEVEL -gt 3 ]
    then
      echo '[DEBUG] Retrieving prometheus version...'
    fi
    PROMETHEUS_VERSION_CURLED="$(curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest |
    grep 'tag_name' | awk '{printf substr($2, 3, length($2)-4)}')"

    if [[ -z $PROMETHEUS_VERSION_CURLED ]]
    then
      echo '[ERROR] System was not able to retrieve prometheus version check your internet connection'
      exit 1
    fi

    if [ $LOG_LEVEL -gt 2 ]
    then
      echo "[INFO] prometheus version retrieved: " "$PROMETHEUS_VERSION_CURLED"
    fi
}


function retrieve_alertmanager_version() {
    if [ $LOG_LEVEL -gt 3 ]
    then
      echo '[DEBUG] Retrieving alertmanager version...'
    fi
    ALERTMANAGER_VERSION_CURLED="$(curl -s https://api.github.com/repos/prometheus/alertmanager/releases/latest |
    grep 'tag_name' | awk '{printf substr($2, 3, length($2)-4)}')"

    if [[ -z $ALERTMANAGER_VERSION_CURLED ]]
    then
      echo '[ERROR] System was not able to retrieve alertmanager version check your internet connection'
      exit 1
    fi

    if [ $LOG_LEVEL -gt 2 ]
    then
      echo "[INFO] alertmanager version retrieved: " "$ALERTMANAGER_VERSION_CURLED"
    fi
}


function ensure_versions() {
  # Test if file is correctly filled or if update is request
  if [ "${#NODE_EXPORTER_VERSION}" -lt 5 ] || $UPDATE_NODE_EXPORTER
  then
    retrieve_node_version
    NODE_EXPORTER_VERSION=$NODE_EXPORTER_VERSION_CURLED
  fi

  if [ "${#BLACKBOX_EXPORTER_VERSION}" -lt 5 ] || $UPDATE_BLACKBOX_EXPORTER
  then
    retrieve_blackbox_version
    BLACKBOX_EXPORTER_VERSION=$BLACKBOX_EXPORTER_VERSION_CURLED
  fi

  if [ "${#PROMETHEUS_VERSION}" -lt 5 ] || $UPDATE_PROMETHEUS
  then
    retrieve_prometheus_version
    PROMETHEUS_VERSION=$PROMETHEUS_VERSION_CURLED
  fi

  if [ "${#ALERTMANAGER_VERSION}" -lt 5 ] || $UPDATE_ALERTMANAGER
  then
    retrieve_alertmanager_version
    ALERTMANAGER_VERSION=$ALERTMANAGER_VERSION_CURLED
  fi
}


function store_actual_versions() {
  if [ $LOG_LEVEL -gt 3 ]
  then
    echo '[DEBUG] Storing new versions in .versions file...'
  fi
  cat > .versions << EOM
NODE_EXPORTER_VERSION=$NODE_EXPORTER_VERSION
BLACKBOX_EXPORTER_VERSION=$BLACKBOX_EXPORTER_VERSION
PROMETHEUS_VERSION=$PROMETHEUS_VERSION
ALERTMANAGER_VERSION=$ALERTMANAGER_VERSION
EOM

  chmod 666 .versions
}


function update_versions() {
  ensure_versions
  store_actual_versions
}


function display_node_versions() {
  if $DEBUG_OFFLINE; then NODE_EXPORTER_VERSION_CURLED=""; else retrieve_node_version; fi
  if [ -z "$NODE_EXPORTER_VERSION_CURLED" ]
  then
    NODE_EXPORTER_VERSION_CURLED="You're offline"
  fi
  printf "Highest available version for node_exporter is: %s\n" "$NODE_EXPORTER_VERSION_CURLED"

  printf "Installation version for node_exporter will be: %s\n" "$NODE_EXPORTER_VERSION"

  INSTALLED_NODE_EXPORTER_VERSION=$(/usr/local/bin/node_exporter --version 2>&1 | awk 'NR==1 {printf $3}')
  if [ "${#INSTALLED_NODE_EXPORTER_VERSION}" -lt 5 ]
  then
    INSTALLED_NODE_EXPORTER_VERSION="Not installed"
  fi
  printf "Actual version of node_exporter is: %s\n\n" "$INSTALLED_NODE_EXPORTER_VERSION"
}


function display_blackbox_versions() {
  if $DEBUG_OFFLINE; then BLACKBOX_EXPORTER_VERSION_CURLED=""; else retrieve_blackbox_version; fi
  if [ -z "$BLACKBOX_EXPORTER_VERSION_CURLED" ]
  then
    BLACKBOX_EXPORTER_VERSION_CURLED="You're offline"
  fi
  printf "Highest available version for blackbox_exporter is: %s\n" "$BLACKBOX_EXPORTER_VERSION_CURLED"

  printf "Installation version for blackbox_exporter will be: %s\n" "$BLACKBOX_EXPORTER_VERSION"

  INSTALLED_BLACKBOX_EXPORTER_VERSION=$(/usr/local/bin/blackbox_exporter --version 2>&1 | awk 'NR==1 {printf $3}')
  if [ "${#INSTALLED_BLACKBOX_EXPORTER_VERSION}" -lt 5 ]
  then
    INSTALLED_BLACKBOX_EXPORTER_VERSION="Not installed"
  fi
  printf "Actual version of blackbox_exporter is: %s\n\n" "$INSTALLED_BLACKBOX_EXPORTER_VERSION"
}


function display_prometheus_versions() {
  if $DEBUG_OFFLINE; then PROMETHEUS_VERSION_CURLED=""; else retrieve_prometheus_version; fi
  if [ -z "$PROMETHEUS_VERSION_CURLED" ]
  then
    PROMETHEUS_VERSION_CURLED="You're offline"
  fi
  printf "Highest available version for Prometheus is: %s\n" "$PROMETHEUS_VERSION_CURLED"

  printf "Installation version for Prometheus will be: %s\n" "$PROMETHEUS_VERSION"

  INSTALLED_PROMETHEUS_VERSION=$(/usr/local/bin/prometheus --version 2>&1 | awk 'NR==1 {printf $3}')
  if [ "${#INSTALLED_PROMETHEUS_VERSION}" -lt 5 ]
  then
    INSTALLED_PROMETHEUS_VERSION="Not installed"
  fi
  printf "Actual version of prometheus is: %s\n\n" "$INSTALLED_PROMETHEUS_VERSION"
  test -f /usr/local/bin/promtool && printf "Promtool is present\n"
}


function display_alertmanager_versions() {
  if $DEBUG_OFFLINE; then ALERTMANAGER_VERSION_CURLED=""; else retrieve_alertmanager_version; fi
  if [ -z "$ALERTMANAGER_VERSION_CURLED" ]
  then
    ALERTMANAGER_VERSION_CURLED="You're offline"
  fi
  printf "Highest available version for alertmanager is: %s\n" "$ALERTMANAGER_VERSION_CURLED"

  printf "Installation version for alertmanager will be: %s\n" "$ALERTMANAGER_VERSION"

  INSTALLED_ALERTMANAGER_VERSION=$(/usr/local/bin/alertmanager --version 2>&1 | awk 'NR==1 {printf $3}')
  if [ "${#INSTALLED_ALERTMANAGER_VERSION}" -lt 5 ]
  then
    INSTALLED_ALERTMANAGER_VERSION="Not installed"
  fi
  printf "Actual version of alertmanager is: %s\n\n" "$INSTALLED_ALERTMANAGER_VERSION"
}


function display_versions() {
  if $DISPLAY_NODE_EXPORTER; then display_node_versions; fi
  if $DISPLAY_BLACKBOX_EXPORTER; then display_blackbox_versions; fi
  if $DISPLAY_PROMETHEUS; then display_prometheus_versions; fi
  if $DISPLAY_ALERTMANAGER; then display_alertmanager_versions; fi
}


function get_status() {

  systemctl >/dev/null 2>&1
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

    service node_exporter status | awk 'NR==1 {printf "Status of node_exporter: %s\n", $0}'
    echo
    service prometheus status | awk 'NR==1 {printf "Status of Prometheus: %s\n", $0}'
    echo

  fi
}


function list_used_ports() {
  if ! command -v lsof &> /dev/null
  then
    echo "Command lsof could not be found, install it first!"
    echo
    exit
  else
    printf "Actual ports used on this machine:\n"
    lsof -n -i -P | grep LISTEN
    echo
  fi
}


function install_node_exporter() {
  printf "Update node_exporter\n"
  useradd --no-create-home --shell /bin/false node_exporter &> /dev/null || grep node_exporter /etc/passwd
  test -f node_exporter-${NODE_EXPORTER_VERSION}.linux-${SYSTEM_ARCH}.tar.gz || curl -OL https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-${SYSTEM_ARCH}.tar.gz

  tar xfz node_exporter-*.tar.gz &> /dev/null
  cp node_exporter-${NODE_EXPORTER_VERSION}.linux-${SYSTEM_ARCH}/node_exporter /usr/local/bin
  chown node_exporter:node_exporter /usr/local/bin/node_exporter

  rm -rf node_exporter-${NODE_EXPORTER_VERSION}*
}


function init_node_exporter() {
  systemctl >/dev/null 2>&1
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
    service node_exporter start >/dev/null 2>&1
    update-rc.d node_exporter defaults
    if [ $? -ne 0 ]
    then
      printf "You have to install node_exporter daemon manually!\nSee for instance ruby gem pleaserun https://github.com/jordansissel/pleaserun\n"
      printf "$ pleaserun --user node_exporter --group node_exporter --install /usr/local/bin/node_exporter --collector.processes --web.listen-address=:%s\n\n" "$NODE_EXPORTER_PORT"
    fi
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


function install_prometheus() {
  printf "Update Prometheus\n"
  useradd --no-create-home --shell /usr/sbin/nologin prometheus &> /dev/null || grep prometheus /etc/passwd
  set_prometheus_folders
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

  systemctl >/dev/null 2>&1
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
    service prometheus start >/dev/null 2>&1
    update-rc.d prometheus defaults
    if [ $? -ne 0 ]
    then
      printf "You have to install and start prometheus daemon manually!\nSee for instance ruby gem pleaserun https://github.com/jordansissel/pleaserun\n"
      printf "$ pleaserun --user prometheus --group prometheus --install /usr/local/bin/prometheus --config.file /etc/prometheus/prometheus.yml --storage.tsdb.path /var/lib/prometheus/ --web.console.templates=/etc/prometheus/consoles --web.console.libraries=/etc/prometheus/console_libraries --web.listen-address=:%s\n\n" "$PROMETHEUS_PORT"
    fi
  fi
}


# shellcheck disable=SC2120
function main() {
  printf 'Selected architecture is %s\n\n' $SYSTEM_ARCH

  if $UPDATE_VERSIONS; then
    update_versions
  fi

  if $DISPLAY_VERSIONS; then
    display_versions
  fi

  if $INSTALL && $NODE_TRIGGER; then
    install_node_exporter
  fi
  if $INSTALL && $PROMETHEUS_TRIGGER; then
    install_prometheus
  fi

  if $EXECUTE && $NODE_TRIGGER; then
    init_node_exporter
  fi
  if $EXECUTE && $PROMETHEUS_TRIGGER; then
    init_prometheus
  fi

  if $EXECUTE; then
    get_status
  fi
}


echo "$MODT"
check_root_rights
echo

if [[ ${#} -eq 0 ]]; then
   usage
fi

flags "$@"
# shellcheck disable=SC2119
main
