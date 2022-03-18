#!/bin/bash
cat >.tmp

export title="Status: $(jq -r '.status' .tmp) |
Alert: $(jq -r '.commonLabels.alertname' .tmp) |
Severity: $(jq -r '.commonLabels.severity' .tmp)"

export msg="Instance: $(jq -r '.commonLabels.instance' .tmp) |
Description: $(jq -r '.commonAnnotations.description' .tmp) |
Summary: $(jq -r '.commonAnnotations.summary' .tmp)"

./lib/pingme teams -w "${QUERY_STRING##*=}" \
--title "$title" \
--msg "$msg"

rm .tmp