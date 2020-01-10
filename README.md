# bash-alarm
Slack Bash console script for sending sending alerts (for now only via Slack).

### Installation
```bash
git clone https://github.com/demmonico/bash-alarm . && chmod +x alarm && chmod +x channels/*
```

```bash
# [optional] ### to define Slack ENV vars
# you may also declare them in ~/.slackrc file. See Slack channel notifier doc
touch channels/.slackrc && nano channels/.slackrc
```

### USAGE

#####   Manually run, just log event
`alarm ps cron`

#####   Manually run, log event and send notification if treshold exceeded
`alarm ps cron 12`

#####   Scheduled run, log event and send notification if treshold exceeded
`watch -n 1 -d './alarm ps cron 12'`
