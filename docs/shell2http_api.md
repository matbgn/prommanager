# Miscellanous notes on HTTP API to trigger shell script


## Firing dummy alert on Alertmanager
    alertmanager_url=http://localhost:9550/api/v1/alerts
    curl -XPOST $alertmanager_url -d '[{"status": "firing","labels": {"alertname": "my_cool_alert_35","service": "curl","severity": "warning","instance": "0"},"annotations": {"summary": "This is a summary","description": "This is a description."},"generatorURL": "http://prometheus.int.example.net/<generating_expression>","startsAt": "2020-07-23T01:05:36+00:00"}]'

## Launch shell2http

    /usr/local/bin/shell2http -port=9560 -cgi /notify './notify_services.sh'

## Simulate alert sent by Alertmanager to PingMe CLI

    shell2http_url=http://localhost:9560/notify
    curl -XPOST $shell2http_url -d '{"receiver":"alert\\.services","status":"firing","alerts":[{"status":"firing","labels":{"alertname":"my_cool_alert_35","instance":"0","service":"curl","severity":"warning"},"annotations":{"description":"This is a description.","summary":"This is a summary"},"startsAt":"2020-07-23T01:05:36Z","endsAt":"0001-01-01T00:00:00Z","generatorURL":"http://prometheus.int.example.net/\u003cgenerating_expression\u003e","fingerprint":"b13d2f13a19f6891"}],"groupLabels":{"alertname":"my_cool_alert_35"},"commonLabels":{"alertname":"my_cool_alert_35","instance":"0","service":"curl","severity":"warning"},"commonAnnotations":{"description":"This is a description.","summary":"This is a summary"},"externalURL":"http://MNB7100051-LTP:9550","version":"4","groupKey":"{}:{alertname=\"my_cool_alert_35\"}","truncatedAlerts":0}'