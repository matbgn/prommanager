#!/bin/bash
cat >.tmp

eval "$(./lib/shdotenv)"

export title="Status: $(jq -r '.status' .tmp) |
Alert: $(jq -r '.commonLabels.alertname' .tmp) |
Severity: $(jq -r '.commonLabels.severity' .tmp)"

export msg="Instance: $(jq -r '.commonLabels.instance' .tmp) |
Description: $(jq -r '.commonAnnotations.description' .tmp) |
Summary: $(jq -r '.commonAnnotations.summary' .tmp)"

eval "set -- $NOTIFY_SERVICES"
while [ $# -gt 0 ]; do
  ./lib/pingme "$1" \
  --title "$title" \
  --msg "$msg"
  shift
done

rm .tmp