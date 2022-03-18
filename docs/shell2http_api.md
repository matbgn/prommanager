# Miscellanous notes on HTTP API to trigger shell script


## Dummy Alert
    alertmanager_url=http://localhost:9550/api/v1/alerts
    curl -XPOST $alertmanager_url -d '[{"status": "firing","labels": {"alertname": "my_cool_alert_35","service": "curl","severity": "warning","instance": "0"},"annotations": {"summary": "This is a summary","description": "This is a description."},"generatorURL": "http://prometheus.int.example.net/<generating_expression>","startsAt": "2020-07-23T01:05:36+00:00"}]'

## Launch shell2http

    ./lib/shell2http -port=9560 -cgi /notify_teams './notify_teams.sh'