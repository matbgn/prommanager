#!/bin/bash
MODT="Welcome to Prometheus manager v3.0.2!"

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

NODE_TRIGGER=false
BLACKBOX_TRIGGER=false
ALERTMANAGER_TRIGGER=false
PROMETHEUS_TRIGGER=false

DISPLAY_VERSIONS=false

UPDATE_VERSIONS=false

INSTALL=false
NODE_EXPORTER_PORT=9500
BLACKBOX_EXPORTER_PORT=9510
ALERTMANAGER_PORT=9550
PROMETHEUS_PORT=9590

# Retrieve list of URLs to watch from .env file in form of:
# BLACKBOX_URL_TO_PROBE="example.com, http://192.247.247.154:1880/"
BLACKBOX_URL_TO_PROBE=""

# Retrieve alert configuration from .env file in following form:
# ALERT_EMAIL_TO="test@example.com,toto@example.com"
ALERT_EMAIL_TO=""
# ALERT_EMAIL_SMTP_FROM="smtp_allowed_sender@example.com"
ALERT_EMAIL_SMTP_FROM=""
# ALERT_EMAIL_SMTP_HOSTNAME_AND_PORT="smtp.gmail.com:587"
ALERT_EMAIL_SMTP_HOSTNAME_AND_PORT=""
# ALERT_EMAIL_SMTP_USER="username" // in some case it's the same as ALERT_EMAIL_SMTP_FROM
ALERT_EMAIL_SMTP_USER=""
# ALERT_EMAIL_SMTP_PASS="my_top_secret_pass"
ALERT_EMAIL_SMTP_PASS=""
# ALERT_WEBHOOK_URL="https://telepush.dev/api/inlets/alertmanager/:ID" -> e.g. for telegram
ALERT_WEBHOOK_URL=""

file=$(cat .env)
for line in $file
do
    eval "${line%=*}"="${line##*=}"
done

EXECUTE=false
KILL_APPS=false
STATUS_APPS=false

REMOVE_APPS=false

function usage {
        echo "Usage: $(basename "$0") [<flags>]" 2>&1
        echo '   -h, --help                          Show this help context'
        echo '   -v, --verbose                       Adaptative verbose mode (-vv for WARN,'
        echo '                                       -vvv for INFO, -vvvv for full debugging)'
        echo '   -V, --versions [--<all|apps>]       Display versions for selected apps'
        echo '                                       e.g. --all | --node | --prom | etc.'
        echo '                                       (see arguments below)'
        echo '   --update-versions [--<all|apps>]    Retrieve last version numbers available'
        echo '                                       for selected apps'
        echo '   -i, --install [--<all|apps>]        Install selected apps'
        echo '   -e, --exec [--<all|apps>]           Execute selected apps'
        echo '   -s, --status [--<all|apps>]         Prompt selected apps status'
        echo '   -k, --kill [--<all|apps>]           Stop selected apps daemons'
        echo '   --remove [--<all|apps>]             Remove all data, users and services for'
        echo '                                       selected apps'
        echo '   --all                               Process script for all available apps'
        echo '                                       (prometheus, node_exporter, etc.)'
        echo '   -n, --node                          Process for node_exporter'
        echo '   -N [<version>]                      Specify node_exporter version'
        echo '   -b, --blackbox                      Process for blackbox_exporter'
        echo '   -B [<version>]                      Specify blackbox_exporter version'
        echo '   -a, --alert                         Process for alertmanager'
        echo '   -A [<version>]                      Specify alertmanager version'
        echo '   -p, --prom                          Process for Prometheus'
        echo '   -P [<version>]                      Specify prometheus version'
        echo '   --list-ports                        List all ports actually used'
        echo '   --arch arm64                        Set architecture, default is amd64'
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
        DISPLAY_VERSIONS=true
        shift # argument
        ;;
      --update-versions)
        UPDATE_VERSIONS=true
        shift # argument
        ;;
      -i|--install)
        INSTALL=true
        shift # argument
        ;;
      -e|--exec)
        EXECUTE=true
        shift # argument
        ;;
      -s|--status)
        STATUS_APPS=true
        shift # argument
        ;;
      -k|--kill)
        KILL_APPS=true
        shift # argument
        ;;
      --remove)
        KILL_APPS=true
        REMOVE_APPS=true
        shift # argument
        ;;
      --all)
        NODE_TRIGGER=true
        BLACKBOX_TRIGGER=true
        PROMETHEUS_TRIGGER=true
        ALERTMANAGER_TRIGGER=true
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
      -b|--blackbox)
        BLACKBOX_TRIGGER=true
        shift # argument
        ;;
      -B)
        check_options_mandatory "$2"
        BLACKBOX_EXPORTER_VERSION="$2"
        BLACKBOX_TRIGGER=true
        shift # argument
        shift # value
        ;;
      -a|--alert)
        ALERTMANAGER_TRIGGER=true
        shift # argument
        ;;
      -A)
        check_options_mandatory "$2"
        ALERTMANAGER_VERSION="$2"
        ALERTMANAGER_TRIGGER=true
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
      --list-ports)
        list_used_ports
        shift # argument
        ;;
      --arch)
        check_options_mandatory "$2"
        SYSTEM_ARCH="$2"
        shift # argument
        shift # value
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
  if [ "$(id -u)" -ne 0 ]
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


function ensure_versions() {
  # Test if file is correctly filled or if update is request
  if [ "${#NODE_EXPORTER_VERSION}" -lt 5 ] || ($NODE_TRIGGER && $UPDATE_VERSIONS)
  then
    retrieve_node_version
    NODE_EXPORTER_VERSION=$NODE_EXPORTER_VERSION_CURLED
  fi

  if [ "${#BLACKBOX_EXPORTER_VERSION}" -lt 5 ] || ($BLACKBOX_TRIGGER && $UPDATE_VERSIONS)
  then
    retrieve_blackbox_version
    BLACKBOX_EXPORTER_VERSION=$BLACKBOX_EXPORTER_VERSION_CURLED
  fi

  if [ "${#ALERTMANAGER_VERSION}" -lt 5 ] || ($ALERTMANAGER_TRIGGER && $UPDATE_VERSIONS)
  then
    retrieve_alertmanager_version
    ALERTMANAGER_VERSION=$ALERTMANAGER_VERSION_CURLED
  fi

  if [ "${#PROMETHEUS_VERSION}" -lt 5 ] || ($PROMETHEUS_TRIGGER && $UPDATE_VERSIONS)
  then
    retrieve_prometheus_version
    PROMETHEUS_VERSION=$PROMETHEUS_VERSION_CURLED
  fi
}


function store_actual_versions() {
  if [ $LOG_LEVEL -gt 3 ]; then echo '[DEBUG] Storing new versions in .versions file...'; fi
  cat > .versions << EOM
NODE_EXPORTER_VERSION=$NODE_EXPORTER_VERSION
BLACKBOX_EXPORTER_VERSION=$BLACKBOX_EXPORTER_VERSION
ALERTMANAGER_VERSION=$ALERTMANAGER_VERSION
PROMETHEUS_VERSION=$PROMETHEUS_VERSION
EOM

  chmod 666 .versions
  if [ $LOG_LEVEL -gt 2 ]; then echo '[INFO] Versions stored locally'; fi
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


function display_versions() {
  if $NODE_TRIGGER; then display_node_versions; fi
  if $BLACKBOX_TRIGGER; then display_blackbox_versions; fi
  if $ALERTMANAGER_TRIGGER; then display_alertmanager_versions; fi
  if $PROMETHEUS_TRIGGER; then display_prometheus_versions; fi
}


function download_node_exporter() {
  if [ $LOG_LEVEL -gt 2 ]; then printf "[INFO] Download node_exporter\n"; fi
  useradd --no-create-home --shell /bin/false node_exporter &> /dev/null || grep node_exporter /etc/passwd
  test -f node_exporter-"$NODE_EXPORTER_VERSION".linux-"$SYSTEM_ARCH".tar.gz ||
  curl -OL https://github.com/prometheus/node_exporter/releases/download/v"$NODE_EXPORTER_VERSION"/node_exporter-"$NODE_EXPORTER_VERSION".linux-"$SYSTEM_ARCH".tar.gz
  echo

  tar xfz node_exporter-*.tar.gz &> /dev/null
  cp node_exporter-"$NODE_EXPORTER_VERSION".linux-"$SYSTEM_ARCH"/node_exporter /usr/local/bin
  chown node_exporter:node_exporter /usr/local/bin/node_exporter

  if [ $LOG_LEVEL -lt 3 ]; then rm -rf node_exporter-"$NODE_EXPORTER_VERSION"*; fi

  printf "node_exporter downloaded\n"
}


function init_node_exporter() {
  if [ $LOG_LEVEL -gt 2 ]; then printf "[INFO] Setting node_exporter daemon\n"; fi

  systemctl >/dev/null 2>&1
  # shellcheck disable=SC2181
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
  else
    update-rc.d node_exporter defaults
    if [ $? -ne 0 ]
    then
      printf "You have to install node_exporter daemon manually!\nSee for instance ruby gem pleaserun https://github.com/jordansissel/pleaserun\n"
      printf "$ pleaserun --user node_exporter --group node_exporter \\\n--install /usr/local/bin/node_exporter --collector.systemd \\\n--collector.processes --web.listen-address=:%s\n\n" "$NODE_EXPORTER_PORT"
    fi
  fi
}


function install_node_exporter() {
  if [ $LOG_LEVEL -gt 3 ]; then echo '[DEBUG] Starting node_exporter installation'; fi
  download_node_exporter
  init_node_exporter
  if [ $LOG_LEVEL -gt 2 ]; then echo '[INFO] node_exporter installed'; fi
}


function download_blackbox_exporter() {
  if [ $LOG_LEVEL -gt 2 ]; then printf "[INFO] Download blackbox_exporter\n"; fi
  useradd --no-create-home --shell /bin/false blackbox_exporter &> /dev/null || grep blackbox_exporter /etc/passwd
  test -f blackbox_exporter-"$BLACKBOX_EXPORTER_VERSION".linux-"$SYSTEM_ARCH".tar.gz ||
  curl -OL https://github.com/prometheus/blackbox_exporter/releases/download/v"$BLACKBOX_EXPORTER_VERSION"/blackbox_exporter-"$BLACKBOX_EXPORTER_VERSION".linux-"$SYSTEM_ARCH".tar.gz
  echo

  tar xfz blackbox_exporter-*.tar.gz &> /dev/null
  cp blackbox_exporter-"$BLACKBOX_EXPORTER_VERSION".linux-"$SYSTEM_ARCH"/blackbox_exporter /usr/local/bin
  chown blackbox_exporter:blackbox_exporter /usr/local/bin/blackbox_exporter

  mkdir /etc/prometheus &> /dev/null
  cp blackbox_exporter-"$BLACKBOX_EXPORTER_VERSION".linux-"$SYSTEM_ARCH"/blackbox.yml /etc/prometheus/
  chown blackbox_exporter:blackbox_exporter /etc/prometheus/blackbox.yml

  if [ $LOG_LEVEL -lt 3 ]; then rm -rf blackbox_exporter-"$BLACKBOX_EXPORTER_VERSION"*; fi

  printf "blackbox_exporter downloaded\n"
}


function config_blackbox_exporter() {
  if [ $LOG_LEVEL -gt 3 ]; then printf "[DEBUG] Config blackbox_exporter\n"; fi
  # Set ipv4 as preferred protocol for blackbox_exporter
  sed -i '4i\    http:' /etc/prometheus/blackbox.yml
  sed -i '5i\      preferred_ip_protocol: "ip4"' /etc/prometheus/blackbox.yml
}


function init_blackbox_exporter() {
  if [ $LOG_LEVEL -gt 2 ]; then printf "[INFO] Setting blackbox_exporter daemon\n"; fi

  systemctl >/dev/null 2>&1
  # shellcheck disable=SC2181
  if [ $? -eq 0 ]
  then

    cat > /etc/systemd/system/blackbox_exporter.service <<EOM
[Unit]
Description=Blackbox Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=blackbox_exporter
Group=blackbox_exporter
Type=simple
ExecStart=/usr/local/bin/blackbox_exporter \
  --config.file /etc/prometheus/blackbox.yml \
  --web.listen-address=:${BLACKBOX_EXPORTER_PORT}

[Install]
WantedBy=multi-user.target
EOM


    systemctl daemon-reload
    systemctl enable blackbox_exporter
  else
    update-rc.d blackbox_exporter defaults
    if [ $? -ne 0 ]
    then
      printf "You have to install blackbox_exporter daemon manually!\nSee for instance ruby gem pleaserun https://github.com/jordansissel/pleaserun\n"
      printf "$ pleaserun --user blackbox_exporter --group blackbox_exporter \\\n--install /usr/local/bin/blackbox_exporter --config.file /etc/prometheus/blackbox.yml\\\n--web.listen-address=:%s\n\n" "$BLACKBOX_EXPORTER_PORT"
    fi
  fi
}


function install_blackbox_exporter() {
  if [ $LOG_LEVEL -gt 3 ]; then echo '[DEBUG] Starting blackbox_exporter installation'; fi
  download_blackbox_exporter
  config_blackbox_exporter
  init_blackbox_exporter
  if [ $LOG_LEVEL -gt 2 ]; then echo '[INFO] blackbox_exporter installed'; fi
}


function download_alertmanager() {
  if [ $LOG_LEVEL -gt 2 ]; then printf "[INFO] Download Alertmanager\n"; fi
  useradd --no-create-home --shell /bin/false alertmanager &> /dev/null || grep alertmanager /etc/passwd
  test -f alertmanager-"$ALERTMANAGER_VERSION".linux-"$SYSTEM_ARCH".tar.gz ||
  curl -OL https://github.com/prometheus/alertmanager/releases/download/v"$ALERTMANAGER_VERSION"/alertmanager-"$ALERTMANAGER_VERSION".linux-"$SYSTEM_ARCH".tar.gz
  echo

  tar xfz alertmanager-*.tar.gz &> /dev/null
  cp alertmanager-"$ALERTMANAGER_VERSION".linux-"$SYSTEM_ARCH"/alertmanager /usr/local/bin
  chown alertmanager:alertmanager /usr/local/bin/alertmanager

  if [ $LOG_LEVEL -lt 3 ]; then rm -rf alertmanager-"$ALERTMANAGER_VERSION"*; fi

  printf "Alertmanager downloaded\n"
}


function set_alertmanager_folders() {
  mkdir /etc/prometheus &> /dev/null
  mkdir -p /var/lib/alertmanager &> /dev/null

  chown alertmanager:alertmanager /var/lib/alertmanager &> /dev/null
  if [ $LOG_LEVEL -gt 3 ]
  then
    printf "Alertmanager directories:\n"
    ls -all /var/lib/ | grep alertmanager
    echo
  fi
}


function config_alertmanager() {
  if [ $LOG_LEVEL -gt 3 ]; then printf "[DEBUG] Config Alertmanager\n"; fi

  cat > /etc/prometheus/alertmanager.yml <<EOM
global:
  smtp_from: $ALERT_EMAIL_SMTP_FROM
  smtp_smarthost: $ALERT_EMAIL_SMTP_HOSTNAME_AND_PORT
  smtp_auth_username: $ALERT_EMAIL_SMTP_USER
  smtp_auth_password: $ALERT_EMAIL_SMTP_PASS
route:
  group_by: ['alertname']
  # How long to initially wait to send a notification for a group
  # of alerts. Allows to wait for an inhibiting alert to arrive or collect
  # more initial alerts for the same group. (Usually ~0s to few minutes.)
  group_wait: 3s
  # How long to wait before sending a notification about new alerts that
  # are added to a group of alerts for which an initial notification has
  # already been sent. (Usually ~5m or more.)
  group_interval: 5s
  # How long to wait before sending a notification again if it has already
  # been sent successfully for an alert. (Usually ~3h or more).
  repeat_interval: 1h
  receiver: 'alert.services'
receivers:
- name: 'alert.services'
  email_configs:
    - to: $ALERT_EMAIL_TO
  webhook_configs:
    - url: $ALERT_WEBHOOK_URL
inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'dev', 'instance']
EOM

  chown alertmanager:alertmanager /etc/prometheus/alertmanager.yml &> /dev/null
}


function config_alert_rules() {
  if [ $LOG_LEVEL -gt 3 ]; then printf "[DEBUG] Config Alert Rules\n"; fi

  cat > /etc/prometheus/alert.rules.yml <<EOM
groups:
- name: alert.rules
  rules:
  - alert: InstanceDown
    expr: up == 0
    for: 5m
    labels:
      severity: "critical"
    annotations:
      summary: "Endpoint {{ \$labels.instance }} down"
      description: "{{ \$labels.instance }} of job {{ \$labels.job }} has been down for more than 5 minutes."
EOM
}


function init_alertmanager() {
  if [ $LOG_LEVEL -gt 2 ]; then printf "[INFO] Setting Alertmanager daemon\n"; fi

  systemctl >/dev/null 2>&1
  # shellcheck disable=SC2181
  if [ $? -eq 0 ]
  then

    cat > /etc/systemd/system/alertmanager.service <<EOM
[Unit]
Description=Prometheus Altermanager
Wants=network-online.target
After=network-online.target

[Service]
User=alertmanager
Group=alertmanager
Type=simple
ExecStart=/usr/local/bin/alertmanager \
  --config.file /etc/prometheus/alertmanager.yml \
  --cluster.listen-address= \
  --storage.path /var/lib/alertmanager/ \
  --web.listen-address=:${ALERTMANAGER_PORT}

[Install]
WantedBy=multi-user.target
EOM


    systemctl daemon-reload
    systemctl enable alertmanager
  else
    update-rc.d alertmanager defaults
    if [ $? -ne 0 ]
    then
      printf "You have to install alertmanager daemon manually!\nSee for instance ruby gem pleaserun https://github.com/jordansissel/pleaserun\n"
      printf "$ pleaserun --user alertmanager --group alertmanager \\\n--install /usr/local/bin/alertmanager --config.file /etc/prometheus/alertmanager.yml\\\n--web.listen-address=:%s\n\n" "$ALERTMANAGER_PORT"
    fi
  fi
}


function install_alertmanager() {
  if [ $LOG_LEVEL -gt 3 ]; then echo '[DEBUG] Starting alertmanager installation'; fi
  download_alertmanager
  set_alertmanager_folders
  config_alertmanager
  config_alert_rules
  init_alertmanager
  if [ $LOG_LEVEL -gt 2 ]; then echo '[INFO] Alertmanager installed'; fi
}


function set_prometheus_folders() {
  mkdir /etc/prometheus &> /dev/null
  mkdir /var/lib/prometheus &> /dev/null

  chown prometheus:prometheus /etc/prometheus &> /dev/null
  chown prometheus:prometheus /var/lib/prometheus &> /dev/null
  if [ $LOG_LEVEL -gt 3 ]
  then
    ls /etc | grep prometheus | awk '{printf "Directories %s:\n", $1}'
    ls -all /etc | grep prometheus
    ls -all /var/lib/ | grep prometheus
    echo
  fi
}


function download_prometheus() {
  if [ $LOG_LEVEL -gt 2 ]; then printf "[INFO] Download prometheus\n"; fi
  useradd --no-create-home --shell /usr/sbin/nologin prometheus &> /dev/null || grep prometheus /etc/passwd
  set_prometheus_folders
  test -f prometheus-"$PROMETHEUS_VERSION".linux-"$SYSTEM_ARCH".tar.gz ||
  curl -OL https://github.com/prometheus/prometheus/releases/download/v"$PROMETHEUS_VERSION"/prometheus-"$PROMETHEUS_VERSION".linux-"$SYSTEM_ARCH".tar.gz
  echo

  tar xfz prometheus-*.tar.gz &> /dev/null
  cp prometheus-"$PROMETHEUS_VERSION".linux-"$SYSTEM_ARCH"/prometheus /usr/local/bin
  cp prometheus-"$PROMETHEUS_VERSION".linux-"$SYSTEM_ARCH"/promtool /usr/local/bin
  chown prometheus:prometheus /usr/local/bin/prometheus
  chown prometheus:prometheus /usr/local/bin/promtool

  cp -r prometheus-"$PROMETHEUS_VERSION".linux-"$SYSTEM_ARCH"/consoles /etc/prometheus
  cp -r prometheus-"$PROMETHEUS_VERSION".linux-"$SYSTEM_ARCH"/console_libraries /etc/prometheus
  chown -R prometheus:prometheus /etc/prometheus/consoles
  chown -R prometheus:prometheus /etc/prometheus/console_libraries

  if [ $LOG_LEVEL -lt 3 ]; then rm -rf prometheus-"$PROMETHEUS_VERSION"*; fi

  printf "Prometheus downloaded\n"
}


function config_prometheus() {
  if [ $LOG_LEVEL -gt 3 ]; then printf "[DEBUG] Config prometheus\n"; fi

  cat > /etc/prometheus/prometheus.yml <<EOM
global:
  scrape_interval:     15s
  evaluation_interval: 15s

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  - alert.rules.yml

# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
      - targets: ['localhost:${ALERTMANAGER_PORT}']

scrape_configs:
  - job_name: 'prometheus'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:${PROMETHEUS_PORT}']

  - job_name: 'node_exporter'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:${NODE_EXPORTER_PORT}']

  - job_name: "http_probe"
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
     - targets: [$BLACKBOX_URL_TO_PROBE]
    relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: 127.0.0.1:${BLACKBOX_EXPORTER_PORT}
EOM
}


function init_prometheus() {
  if [ $LOG_LEVEL -gt 2 ]; then printf "[INFO] Setting prometheus daemon\n"; fi
  systemctl >/dev/null 2>&1
  # shellcheck disable=SC2181
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
  --storage.tsdb.no-lockfile \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.listen-address=:${PROMETHEUS_PORT}
  ExecReload=/bin/kill -HUP ${MAINPID}

[Install]
  WantedBy=multi-user.target
EOM

    systemctl daemon-reload
    systemctl enable prometheus
  else
    update-rc.d prometheus defaults
    if [ $? -ne 0 ]
    then
      printf "You have to install and start prometheus daemon manually!\nSee for instance ruby gem pleaserun https://github.com/jordansissel/pleaserun\n"
      printf "$ pleaserun --user prometheus --group prometheus --install /usr/local/bin/prometheus --config.file /etc/prometheus/prometheus.yml --storage.tsdb.path /var/lib/prometheus/ --storage.tsdb.no-lockfile --web.console.templates=/etc/prometheus/consoles --web.console.libraries=/etc/prometheus/console_libraries --web.listen-address=:%s\n\n" "$PROMETHEUS_PORT"
    fi
  fi
}


function install_prometheus() {
  if [ $LOG_LEVEL -gt 3 ]; then echo '[DEBUG] Starting prometheus installation'; fi
  download_prometheus
  config_prometheus
  init_prometheus
  if [ $LOG_LEVEL -gt 2 ]; then echo '[INFO] prometheus installed'; fi
}


function install_apps() {
  if $NODE_TRIGGER; then install_node_exporter; fi
  if $BLACKBOX_TRIGGER; then install_blackbox_exporter; fi
  if $ALERTMANAGER_TRIGGER; then install_alertmanager; fi
  if $PROMETHEUS_TRIGGER; then install_prometheus; fi
}


function start_apps() {
  if $NODE_TRIGGER; then service node_exporter start; fi
  if $BLACKBOX_TRIGGER; then service blackbox_exporter start; fi
  if $ALERTMANAGER_TRIGGER; then service alertmanager start; fi
  if $PROMETHEUS_TRIGGER; then service prometheus start; fi
}


function stop_apps() {
  if $NODE_TRIGGER; then service node_exporter stop; fi
  if $BLACKBOX_TRIGGER; then service blackbox_exporter stop; fi
  if $ALERTMANAGER_TRIGGER; then service alertmanager stop; fi
  if $PROMETHEUS_TRIGGER; then service prometheus stop; fi
}


function get_node_status() {
  service node_exporter status | awk 'NR==3 {printf "Status of node_exporter: %s\n", $2}'
}


function get_blackbox_status() {
  service blackbox_exporter status | awk 'NR==3 {printf "Status of blackbox_exporter: %s\n", $2}'
}


function get_alertmanager_status() {
  service alertmanager status | awk 'NR==3 {printf "Status of Alertmanager: %s\n", $2}'
}


function get_prometheus_status() {
  service prometheus status | awk 'NR==3 {printf "Status of Prometheus: %s\n", $2}'
}


function get_status() {
  if $NODE_TRIGGER; then get_node_status; fi
  if $BLACKBOX_TRIGGER; then get_blackbox_status; fi
  if $ALERTMANAGER_TRIGGER; then get_alertmanager_status; fi
  if $PROMETHEUS_TRIGGER; then get_prometheus_status; fi
  echo
}


function remove_node_exporter() {
  rm /usr/local/bin/node_exporter

  deluser --remove-home node_exporter

  systemctl >/dev/null 2>&1
  # shellcheck disable=SC2181
  if [ $? -eq 0 ]
  then
    rm /etc/systemd/system/node_exporter.service
    systemctl daemon-reload
  else
    rm /etc/init.d/node_exporter
    rm /etc/default/node_exporter
    update-rc.d node_exporter remove
  fi
}


function remove_blackbox_exporter() {
  rm /usr/local/bin/blackbox_exporter

  deluser --remove-home blackbox_exporter

  systemctl >/dev/null 2>&1
  # shellcheck disable=SC2181
  if [ $? -eq 0 ]
  then
    rm /etc/systemd/system/blackbox_exporter.service
    systemctl daemon-reload
  else
    rm /etc/init.d/blackbox_exporter
    rm /etc/default/blackbox_exporter
    update-rc.d blackbox_exporter remove
  fi
}


function remove_alertmanager() {
  rm /usr/local/bin/alertmanager

  deluser --remove-home alertmanager

  systemctl >/dev/null 2>&1
  # shellcheck disable=SC2181
  if [ $? -eq 0 ]
  then
    rm /etc/systemd/system/alertmanager.service
    systemctl daemon-reload
  else
    rm /etc/init.d/alertmanager
    rm /etc/default/alertmanager
    update-rc.d alertmanager remove
  fi
}


function remove_prometheus() {
  rm /usr/local/bin/prometheus
  rm /usr/local/bin/promtool
  rm -rf /etc/prometheus
  rm -rf /var/lib/prometheus/

  deluser --remove-home prometheus

  systemctl >/dev/null 2>&1
  # shellcheck disable=SC2181
  if [ $? -eq 0 ]
  then
    rm /etc/systemd/system/prometheus.service
    systemctl daemon-reload
  else
    rm /etc/init.d/prometheus
    rm /etc/default/prometheus
    update-rc.d prometheus remove
  fi
}


function remove_apps() {
  if $NODE_TRIGGER; then remove_node_exporter; fi
  if $BLACKBOX_TRIGGER; then remove_blackbox_exporter; fi
  if $ALERTMANAGER_TRIGGER; then remove_alertmanager; fi
  if $PROMETHEUS_TRIGGER; then remove_prometheus; fi
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


# shellcheck disable=SC2120
function main() {
  printf 'Selected architecture is %s\n\n' "$SYSTEM_ARCH"

  if $KILL_APPS; then
    stop_apps
    sleep 1
    if (! $STATUS_APPS); then get_status; fi
  fi

  if $REMOVE_APPS; then
    remove_apps
  fi

  update_versions

  if $DISPLAY_VERSIONS; then
    display_versions
  fi

  if $INSTALL; then
    install_apps
  fi

  if $EXECUTE; then
    start_apps
    sleep 1
    if (! $STATUS_APPS); then get_status; fi
  fi

  if $STATUS_APPS; then
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
