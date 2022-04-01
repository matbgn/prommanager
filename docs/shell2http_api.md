# Miscellanous notes on HTTP API to trigger shell script

## Firing dummy alert on Alertmanager
    alertmanager_url=http://localhost:9550/api/v1/alerts
    curl -XPOST $alertmanager_url -d '[{"status": "firing","labels": {"alertname": "MY_ALERT_XX","service": "CURL","severity": "critical","instance": "0"},"annotations": {"summary": "HTTP probe failed (instance http://localhost/)","description": "Probe failed\n  VALUE = 0\n  LABELS = map[__name__:probe_success instance:http://localhost/ job:http_probe]"},"generatorURL": "http://localhost:9590/graph","startsAt": "2020-07-23T01:05:36+00:00"}]'

<table border="0">
  <tr>
    <td>:bulb:</td>
    <td>Don't forget to iterate your alerts (MY_ALERT_XX) since Alertmanager prevent repetition from rules</td>
  </tr>
</table>

## Launch shell2http

    /usr/local/bin/shell2http -port=9560 -cgi /notify './notify_services.sh'

## Simulate alert sent by Alertmanager to PingMe CLI

    shell2http_url=http://localhost:9560/notify
    curl -XPOST $shell2http_url -d '{"receiver":"alert\\.services","status":"firing","alerts":[{"status":"firing","labels":{"alertname":"MY_ALERT_XX","instance":"0","job":"http_probe","severity":"critical"},"annotations":{"description":"Probe failed\n  VALUE = 0\n  LABELS = map[__name__:probe_success instance:http://localhost/ job:http_probe]","summary":"HTTP probe failed (instance http://localhost/)"},"startsAt":"2022-04-01T11:41:16.014Z","endsAt":"2022-04-01T11:41:46.014Z","generatorURL":"http://localhost:9590/graph","fingerprint":"b13d2f13a19f6891"}],"groupLabels":{"alertname":"MY_ALERT_XX"},"commonLabels":{"alertname":"MY_ALERT_XX","instance":"0","job":"http_probe","severity":"critical"},"commonAnnotations":{"description":"Probe failed\n  VALUE = 0\n  LABELS = map[__name__:probe_success instance:http://localhost/ job:http_probe]","summary":"HTTP probe failed (instance http://localhost/)"},"externalURL":"http://localhost:9550","version":"4","groupKey":"{}:{alertname=\"MY_ALERT_XX\"}","truncatedAlerts":0}'